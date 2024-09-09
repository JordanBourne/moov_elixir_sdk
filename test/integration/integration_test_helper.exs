ExUnit.start()

Mix.Task.run("loadconfig", ["config/dev.exs"])
Application.ensure_all_started(:moov_elixir_sdk)
