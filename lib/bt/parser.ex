defmodule Bt.Parser do
  @moduledoc """
  Parser for output of some bluetoothctl commands
  """

  alias Bt.CLI.Config

  @spec parse_devices(String.t()) :: map
  def parse_devices(data) do
    data
    |> String.split("\n", trim: true)
    |> Enum.filter(&String.starts_with?(&1, "Device"))
    |> Enum.reduce(
      %{},
      fn x, acc ->
        [_, mac, name] = String.split(x, " ", parts: 3)
        Map.put(acc, mac, name)
      end
    )
    |> Enum.sort_by(&elem(&1, 1))
    |> Enum.into(%{})
  end

  @spec parse_adapters(String.t()) :: list
  def parse_adapters(data) do
    data
    |> String.split("\n", trim: true)
    |> Enum.filter(&String.starts_with?(&1, "Controller"))
    |> Enum.reduce(
      [],
      fn x, acc ->
        [_, mac, name, _text] = String.split(x, " ")

        selected_mac = Config.adapter()

        map =
          %{}
          |> Map.put(:mac, mac)
          |> Map.put(:name, name)
          |> Map.put(:is_selected, mac == selected_mac)

        acc ++ [map]
      end
    )
    |> Enum.sort_by(& &1.name)
  end
end
