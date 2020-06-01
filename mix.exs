defmodule Bt.MixProject do
  use Mix.Project

  @app :bt

  def project do
    [
      app: @app,
      version: "0.2.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      escript: escript(),
      deps: deps(),
      name: "Bt",
      description: description(),
      package: package()
    ]
  end

  defp escript do
    [main_module: Bt.CLI, path: "bin/#{@app}"]
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
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dialyxir, "~> 0.4", only: :dev},
      {:credo, "~> 1.4", only: :dev}
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
