defmodule Bt.Parser do
  @moduledoc """
  Parser for output of some bluetoothctl commands
  """

  alias Bt.{CLI.Config, Bluetoothctl}

  @spec parse_devices :: map
  def parse_devices do
    {res, _code} = System.cmd("bluetoothctl", ["devices"])

    res
    |> String.split("\n", trim: true)
    |> Enum.reduce(
      %{},
      fn x, acc ->
        [_, mac, name] = String.split(x, " ", parts: 3)
        Map.put(acc, mac, name)
      end
    )
    |> Enum.sort_by(&(elem(&1, 1)))
    |> Enum.into(%{})
  end

  @spec parse_adapters :: list
  def parse_adapters do
    {res, _code} = System.cmd("bluetoothctl", ["list"])

    res
    |> String.split("\n", trim: true)
    |> Enum.reduce(
      [],
      fn x, acc ->
        [_, mac, name, _text] = String.split(x, " ")

        selected_mac = Config.adapter()

        Bluetoothctl.start_link()
        Bluetoothctl.select(mac)

        map = %{}
          |> Map.put(:mac, mac)
          |> Map.put(:name, name)
          |> Map.put(:is_selected, mac == selected_mac)
          |> Map.put(:is_powered, Bluetoothctl.powered?())

        acc ++ [map]
      end
    )
    |> Enum.sort_by(&(&1.name))
  end
end
