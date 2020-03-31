defmodule Bt.MixProject do
  use Mix.Project

  def project do
    [
      app: :bt,
      version: "0.1.2",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: Bt.CLI],
      deps: deps(),
      name: "Bt",
      description: description(),
      package: package(),
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_cli, "~> 0.1.6"},
      {:toml, "~> 0.6.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
    ]
  end

  defp description do
    "Convenient wrapper around bluetoothctl"
  end

  defp package do
    [
      name: "bt",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/fly1ngDream/bt"}
    ]
  end
end
