defmodule Bt.MixProject do
  use Mix.Project

  @app :bt

  def project do
    [
      app: @app,
      version: "0.3.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      escript: escript(),
      deps: deps(),
      name: "Bt",
      description: description(),
      package: package(),
      aliases: aliases()
    ]
  end

  defp escript do
    [
      main_module: Bt.CLI,
      path: if(Mix.env() == :prod, do: Atom.to_string(@app), else: "bin/#{@app}")
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
      links: %{"GitHub" => "https://github.com/yevhenshymotiuk/bt"}
    ]
  end

  defp aliases do
    [
      "escript.install": "escript.install #{escript()[:path]}"
    ]
  end
end
