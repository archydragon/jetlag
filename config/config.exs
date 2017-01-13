use Mix.Config

config :jetlag,
  config_file: System.get_env("JETLAG_CONFIG_FILE") || "jetlag.yml"

config :logger,
  level: :debug

config :nadia,
  recv_timeout: 10
