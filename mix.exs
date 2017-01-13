defmodule Jetlag.Mixfile do
  use Mix.Project

  def project do
    [app: :jetlag,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger,
                    :yaml_elixir,
                    :romeo,
                    :nadia
    ]]
  end

  defp deps do
    [{:yaml_elixir, "~> 1.3.0"},
     {:romeo, "~> 0.7"},
     {:nadia, "~> 0.4.2"}]
  end
end
