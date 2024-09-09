defmodule Integration.MoovApiTest do
  use ExUnit.Case, async: true

  @primary_account_id "cd0eeb3a-501e-4d38-b6b3-c06c3c733047"
  # @individual_account_id "b0685ac6-caf2-48b4-bd9a-3efd3b38ade5"
  @transaction_idempotency_key "c0d665c0-1359-459f-ada6-43155cda5732"
  @test_customer %{
    "foreignID" => "123456789",
    "email" => "test@example.com",
    "name" => %{
      "firstName" => "Test",
      "lastName" => "Customer"
    }
  }
  @test_bank_account %{
    "accountNumber" => "0004321567000",
    "bankAccountType" => "checking",
    "holderName" => "Test Customer",
    "holderType" => "individual",
    "routingNumber" => "011000015"
  }

  setup do
    Application.put_env(:moov_elixir_sdk, :http_client, HTTPoison)
    :ok
  end

  test "health check with real API" do
    assert :ok = MoovElixirSdk.health()
  end

  test "get_api_key with real API" do
    assert :ok = MoovElixirSdk.get_api_key()
  end

  test "list_accounts integration" do
    assert {:ok, accounts} = MoovElixirSdk.list_accounts()
    assert is_list(accounts)
    IO.inspect(accounts)
    assert Enum.any?(accounts, fn account -> account["accountID"] == @primary_account_id end)
  end

  test "get_account integration" do
    assert {:ok, account} = MoovElixirSdk.get_account(@primary_account_id)
    assert @primary_account_id == account["accountID"]
  end

  test "create user and make payment flow" do
    assert {:ok, accounts} = MoovElixirSdk.list_accounts()

    # Delete account if it already exists
    Enum.find(accounts, fn account -> account["foreignID"] == @test_customer["foreignID"] end)
    |> case do
      nil -> :ok
      account -> assert :ok = MoovElixirSdk.delete_account(account["accountID"])
    end

    # Create customer account
    assert {:ok, account} = MoovElixirSdk.create_individual_account(@test_customer)
    assert @test_customer["email"] == account["profile"]["individual"]["email"]
    assert "individual" == account["accountType"]
    assert @test_customer["foreignID"] == account["foreignID"]

    # Create linked bank account
    assert {:ok, bank_account} =
             MoovElixirSdk.create_bank_account(account["accountID"], @test_bank_account)

    assert @test_bank_account["account"]["accountNumber"] ==
             bank_account["account"]["accountNumber"]

    # Add send-funds capability to the test user
    assert {:ok, capabilities} = MoovElixirSdk.get_capabilities(account["accountID"])

    assert false ==
             Enum.any?(capabilities, fn capability -> capability["capability"] == "send-funds" end)

    assert {:ok, capabilities} = MoovElixirSdk.add_capability(account["accountID"], "send-funds")

    send_funds_capability =
      Enum.find(capabilities, fn capability -> capability["capability"] == "send-funds" end)

    expected_requirements = [
      "account.tos-acceptance",
      "individual.address",
      "individual.birthdate",
      "individual.ssn"
    ]

    Enum.each(expected_requirements, fn requirement ->
      assert Enum.any?(send_funds_capability["requirements"]["currentlyDue"], fn due ->
               due == requirement
             end)
    end)

    # Send funds to the test bank account
    assert {:ok, %{"createdOn" => _, "transferID" => transfer_id}} =
             MoovElixirSdk.create_transfer(
               @transaction_idempotency_key,
               account["accountID"],
               @primary_account_id,
               100,
               "Test Description"
             )

    assert transfer_id == "bananas"

    assert :ok = MoovElixirSdk.delete_account(account["accountID"])
  end
end
