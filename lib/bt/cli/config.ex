defmodule Bt.CLI.Config do
  @moduledoc """
  Configuration for command line interface
  """

  import Bt.Map

  @file_path Path.expand("~/.btrc.toml")

  @spec read :: map
  def read do
    case Toml.decode_file(@file_path) do
      {:ok, content} -> content
      {:error, _reason} -> %{}
    end
  end

  @spec adapter :: String.t()
  def adapter do
    Map.get(read(), "adapter", "")
  end

  @spec aliases :: map
  def aliases do
    Map.get(read(), "aliases", %{})
  end

  @spec add_alias(String.t(), String.t()) :: :ok | {:error, File.posix()}
  def add_alias(device_mac, name) do
    aliases()
    |> swap()
    |> Map.put(device_mac, name)
    |> Enum.into(%{})
    |> swap()
    |> write_aliases()
  end

  @spec write_adapter(String.t()) :: :ok | {:error, File.posix()}
  def write_adapter(adapter) do
    write_config(adapter, aliases())
  end

  @spec write_aliases(map) :: :ok | {:error, File.posix()}
  def write_aliases(aliases) do
    write_config(adapter(), aliases)
  end

  @spec write_config(String.t(), map) :: :ok | {:error, File.posix()}
  def write_config(adapter_mac, aliases) do
    adapter_config = "adapter = \"#{adapter_mac}\""

    aliases_list =
      aliases
      |> Enum.map(fn {name, mac} -> "#{name} = \"#{mac}\"" end)
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
