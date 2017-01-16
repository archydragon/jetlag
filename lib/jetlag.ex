defmodule Jetlag do
  require Logger
  use Application

  def start(_type, _args) do
    # fetch configuration from YAML source which name is passed as environment
    # variable, see config.exs
    config_file = Application.fetch_env!(:jetlag, :config_file)
    config_path = File.cwd! |> Path.join(config_file)
    parsed_config = YamlElixir.read_from_file(config_path)

    Application.put_env(:jetlag, :config, parsed_config)

    import Supervisor.Spec, warn: false
    sup_children = [
      worker(Jetlag.Handler.Telegram, []),
      worker(Jetlag.Handler.Jabber, [])
    ]
    sup_opts = [strategy: :one_for_one, name: Jetlag.Supervisor]
    Supervisor.start_link(sup_children, sup_opts)
  end
end
