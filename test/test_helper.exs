ExUnit.start()
Application.put_env(:moov_elixir_sdk, :http_client, MoovElixirSdk.HTTPoisonMock)
Mox.defmock(MoovElixirSdk.HTTPoisonMock, for: HTTPoison.Base)
