defmodule Bt.CLI.Config do
  @file_name "~/.btrc.toml"

  def read do
    {:ok, content} = Toml.decode_file(Path.expand(@file_name))
    content
  end

  def read_aliases do
    read() |> Map.get("aliases", %{})
  end
end
