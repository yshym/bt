defmodule Bt.Parser do
  alias Bt.{CLI.Config, Bluetoothctl}

  def parse_output(:devices) do
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
  end
  def parse_output(:adapters) do
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
          |> Map.put(:is_powered, Bluetoothctl.is_powered())

        acc ++ [map]
      end
    )
  end
end
