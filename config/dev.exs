import Config

config :moov_elixir_sdk,
  moov_public_key: System.get_env("MOOV_PUBLIC_KEY"),
  moov_private_key: System.get_env("MOOV_PRIVATE_KEY"),
  http_client: HTTPoison
