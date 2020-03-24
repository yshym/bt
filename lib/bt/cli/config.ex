defmodule Bt.CLI.Config do
  @file_path Path.expand("~/.btrc.toml")

  def read do
    {:ok, content} = Toml.decode_file(@file_path)
    content
  end

  def aliases do
    Map.get(read(), "aliases", %{})
  end

  def write_aliases(aliases) do
    list =
      aliases
      |> Enum.map(
        fn {name, mac} -> "#{name} = \"#{mac}\"" end
      )
      |> Enum.join("\n")

    File.write(
      @file_path,
      """
      [aliases]
      #{list}
      """
    )
  end
end
