defmodule Bt.MixProject do
  use Mix.Project

  def project do
    [
      app: :bt,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: Bt.CLI],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_cli, "~> 0.1.6"}
    ]
  end
end
