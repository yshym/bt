defmodule Bt.CLI.Config do
  @file_path Path.expand("~/.btrc.toml")

  def read do
    {:ok, content} = Toml.decode_file(@file_path)
    content
  end

  def adapter do
    Map.get(read(), "adapter", "")
  end

  def aliases do
    Map.get(read(), "aliases", %{})
  end

  def write_adapter(adapter) do
    write_config(adapter, aliases())
  end

  def write_aliases(aliases) do
    write_config(adapter(), aliases)
  end

  def write_config(adapter_mac, aliases) do
    list =
      aliases
      |> Enum.map(
        fn {name, mac} -> "#{name} = \"#{mac}\"" end
      )
      |> Enum.join("\n")

    File.write(
      @file_path,
      """
      adapter = \"#{adapter_mac}\"

      [aliases]
      #{list}
      """
    )
  end
end
