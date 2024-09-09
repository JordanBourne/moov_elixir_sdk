defmodule MoovElixirSdk do
  @moduledoc """
  Elixir SDK for Moov
  Implements API routes for the Moov API
  View Moov API docs at https://docs.moov.io/api/sources/bank-accounts/
  """
  use HTTPoison.Base
  alias MoovElixirSdk.Types

  @base_url "https://api.moov.io"

  @doc """
  Confirms the project is initialized correctly
  """
  @spec health :: :ok | {:error, String.t()}
  def health do
    case get_api_key() do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
    Create bank account for specified account
  """
  @spec create_bank_account(String.t(), Types.bank_account_request()) ::
          {:ok, Types.bank_account_response()} | {:error, String.t()}
  def create_bank_account(account_id, bank_account) do
    account_request = %{
      "account" => bank_account
    }

    with {:ok, auth_header} <- get_auth_header(),
         {:ok, response} <-
           make_request(
             :post,
             "/accounts/#{account_id}/bank-accounts",
             auth_header,
             account_request
           ) do
      {:ok, Jason.decode!(response.body)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
    Get capabilities for specified account
  """
  @spec get_capabilities(String.t()) :: {:ok, [Types.capability()]} | {:error, String.t()}
  def get_capabilities(account_id) do
    with {:ok, auth_header} <- get_auth_header(),
         {:ok, response} <-
           make_request(:get, "/accounts/#{account_id}/capabilities", auth_header) do
      {:ok, Jason.decode!(response.body)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
    Create a transfer to the specified account
  """
  @spec create_transfer(String.t(), String.t(), String.t(), integer(), String.t()) ::
          {:ok, Types.transfer()} | {:error, String.t()}
  def create_transfer(
        idempotency_key,
        from_payment_id,
        destination_payment_id,
        amount,
        description \\ ""
      ) do
    transfer_request = %{
      "amount" => %{
        "value" => amount,
        "currency" => "USD"
      },
      "destination" => %{
        "paymentMethodID" => destination_payment_id
      },
      "source" => %{
        "paymentMethodID" => from_payment_id
      },
      "description" => description
    }

    with {:ok, auth_header} <- get_auth_header(),
         headers = [{"X-Idempotency-Key", idempotency_key}, {"Authorization", auth_header}],
         {:ok, response} <-
           make_request_with_headers(:post, "/transfers", headers, transfer_request) do
      {:ok, Jason.decode!(response.body)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
    Add capability to specified account
  """
  @spec add_capability(String.t(), String.t()) :: {:ok, Types.capability()} | {:error, String.t()}
  def add_capability(account_id, capability) do
    with {:ok, auth_header} <- get_auth_header(),
         {:ok, response} <-
           make_request(:post, "/accounts/#{account_id}/capabilities", auth_header, %{
             capabilities: [capability]
           }) do
      {:ok, Jason.decode!(response.body)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
    Create a new individual account
  """
  @spec create_individual_account(Types.individual_account_request()) ::
          {:ok, Types.account_response()} | {:error, String.t()}
  def create_individual_account(user_details) do
    account_request = %{
      "accountType" => "individual",
      "profile" => %{
        "individual" => %{
          "email" => user_details["email"],
          "name" => user_details["name"]
        }
      },
      "foreignID" => user_details["foreignID"]
    }

    with {:ok, auth_header} <- get_auth_header(),
         {:ok, response} <-
           make_request(:post, "/accounts", auth_header, account_request) do
      {:ok, Jason.decode!(response.body)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Delete one account
  """
  @spec delete_account(String.t()) :: {:ok, Types.account_response()} | {:error, String.t()}
  def delete_account(account_id) do
    with {:ok, auth_header} <- get_auth_header(),
         {:ok, _} <- make_request(:delete, "/accounts/#{account_id}", auth_header) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  List one account
  """
  @spec get_account(String.t()) :: {:ok, Types.account_response()} | {:error, String.t()}
  def get_account(account_id) do
    with {:ok, auth_header} <- get_auth_header(),
         {:ok, response} <- make_request(:get, "/accounts/#{account_id}", auth_header) do
      {:ok, Jason.decode!(response.body)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Lists accounts
  """
  @spec list_accounts :: {:ok, list(Types.account_response())} | {:error, String.t()}
  def list_accounts do
    with {:ok, auth_header} <- get_auth_header(),
         {:ok, response} <- make_request(:get, "/accounts", auth_header) do
      {:ok, Jason.decode!(response.body)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec get_api_key :: :ok | {:error, String.t()}
  def get_api_key do
    with {:ok, auth_header} <- get_auth_header(),
         {:ok, _response} <- make_request(:get, "/ping", auth_header) do
      :ok
    else
      {:error, reason} -> {:error, "API key validation failed: #{reason}"}
    end
  end

  defp get_auth_header do
    with {:ok, public_key} <- get_config_or_env(:moov_public_key),
         {:ok, private_key} <- get_config_or_env(:moov_private_key) do
      {:ok, "Basic " <> Base.encode64("#{public_key}:#{private_key}")}
    end
  end

  defp get_config_or_env(key) do
    case Application.get_env(:moov_elixir_sdk, key) || System.get_env(String.upcase("#{key}")) do
      nil -> {:error, "Missing #{key}"}
      value -> {:ok, value}
    end
  end

  defp make_request(method, path, auth_header, body) do
    url = @base_url <> path
    headers = [{"Authorization", auth_header}]

    case http_client().request(method, url, Jason.encode!(body), headers) do
      {:ok, %HTTPoison.Response{status_code: status, body: response_body}}
      when status in 200..299 ->
        {:ok, %{status_code: status, body: response_body}}

      {:ok, %HTTPoison.Response{status_code: status, body: response_body}} ->
        {:error, "HTTP #{status}: #{response_body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request failed: #{reason}"}
    end
  end

  defp make_request(method, path, auth_header) do
    url = @base_url <> path
    headers = [{"Authorization", auth_header}]

    case http_client().request(method, url, "", headers) do
      {:ok, %HTTPoison.Response{status_code: status, body: body}} when status in 200..299 ->
        {:ok, %{status_code: status, body: body}}

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        {:error, "HTTP #{status}: #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request failed: #{reason}"}
    end
  end

  defp make_request_with_headers(method, path, headers, body) do
    url = @base_url <> path

    IO.inspect(url)

    case http_client().request(method, url, Jason.encode!(body), headers) do
      {:ok, %HTTPoison.Response{status_code: status, body: response_body}}
      when status in 200..299 ->
        {:ok, %{status_code: status, body: response_body}}

      {:ok, %HTTPoison.Response{status_code: status, body: response_body}} ->
        {:error, "HTTP #{status}: #{response_body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request failed: #{reason}"}
    end
  end

  defp http_client do
    Application.get_env(:moov_elixir_sdk, :http_client, HTTPoison)
  end
end
