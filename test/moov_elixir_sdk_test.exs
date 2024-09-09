defmodule MoovElixirSdkTest do
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  setup do
    Application.put_env(:moov_elixir_sdk, :moov_public_key, "test_public_key")
    Application.put_env(:moov_elixir_sdk, :moov_private_key, "test_private_key")
    :ok
  end

  describe "health/0" do
    test "returns :ok when API keys are valid" do
      MoovElixirSdk.HTTPoisonMock
      |> expect(:request, fn :get,
                             "https://api.moov.io/ping",
                             "",
                             [{"Authorization", "Basic " <> _}] ->
        {:ok, %HTTPoison.Response{status_code: 200, body: "OK"}}
      end)

      assert :ok == MoovElixirSdk.health()
    end

    test "returns error when API request fails" do
      MoovElixirSdk.HTTPoisonMock
      |> expect(:request, fn :get,
                             "https://api.moov.io/ping",
                             "",
                             [{"Authorization", "Basic " <> _}] ->
        {:error, %HTTPoison.Error{reason: "connection_failed"}}
      end)

      assert MoovElixirSdk.health() ==
               {:error, "API key validation failed: HTTP request failed: connection_failed"}
    end
  end

  describe "get_api_key/0" do
    test "returns :ok when both keys are present and valid" do
      MoovElixirSdk.HTTPoisonMock
      |> expect(:request, fn :get,
                             "https://api.moov.io/ping",
                             "",
                             [{"Authorization", "Basic " <> _}] ->
        {:ok, %HTTPoison.Response{status_code: 200, body: "OK"}}
      end)

      assert MoovElixirSdk.get_api_key() == :ok
    end

    test "returns error when public key is missing" do
      Application.put_env(:moov_elixir_sdk, :moov_public_key, nil)

      assert MoovElixirSdk.get_api_key() ==
               {:error, "API key validation failed: Missing moov_public_key"}
    end

    test "returns error when private key is missing" do
      Application.put_env(:moov_elixir_sdk, :moov_private_key, nil)

      assert MoovElixirSdk.get_api_key() ==
               {:error, "API key validation failed: Missing moov_private_key"}
    end

    test "returns error when API returns non-200 status" do
      MoovElixirSdk.HTTPoisonMock
      |> expect(:request, fn :get,
                             "https://api.moov.io/ping",
                             "",
                             [{"Authorization", "Basic " <> _}] ->
        {:ok, %HTTPoison.Response{status_code: 401, body: "Unauthorized"}}
      end)

      assert MoovElixirSdk.get_api_key() ==
               {:error, "API key validation failed: HTTP 401: Unauthorized"}
    end
  end

  describe "list_bank_accounts/0" do
    test "returns list of accounts when successful" do
      MoovElixirSdk.HTTPoisonMock
      |> expect(:request, fn :get,
                             "https://api.moov.io/accounts",
                             "",
                             [{"Authorization", "Basic " <> _}] ->
        {:ok, %HTTPoison.Response{status_code: 200, body: ~s([{"id": "1", "name": "Account 1"}])}}
      end)

      assert MoovElixirSdk.list_bank_accounts() == {:ok, [%{"id" => "1", "name" => "Account 1"}]}
    end

    test "returns error when API request fails" do
      MoovElixirSdk.HTTPoisonMock
      |> expect(:request, fn :get,
                             "https://api.moov.io/accounts",
                             "",
                             [{"Authorization", "Basic " <> _}] ->
        {:error, %HTTPoison.Error{reason: "connection_failed"}}
      end)

      assert MoovElixirSdk.list_bank_accounts() ==
               {:error, "HTTP request failed: connection_failed"}
    end
  end
end
