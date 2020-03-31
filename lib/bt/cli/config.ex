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
    adapter_config = "adapter = \"#{adapter_mac}\""

    aliases_list =
      aliases
      |> Enum.map(
        fn {name, mac} -> "#{name} = \"#{mac}\"" end
      )
      |> Enum.join("\n")

    aliases_config =
      if String.trim(aliases_list) == "" do
        ""
      else
        """
        [aliases]
        #{aliases_list}
        """
      end

    config = "#{adapter_config}\n\n#{aliases_config}"

    File.write(@file_path, config)
  end
end
