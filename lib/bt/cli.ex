defmodule Bt.CLI do
  use ExCLI.DSL, escript: true

  name "mycli"
  description "Bluetooth CLI"
  long_description ~s"""
  Handling bluetooth devices from the shell
  """

  command :connect do
    aliases [:con]
    description "Connect device"
    long_description """
    Connect bluetooth device
    """

    argument :device

    run context do
      System.cmd("bluetoothctl", ["connect", context.device])
    end
  end

  command :devices do
    aliases [:devs]
    description "List devices"
    long_description """
    List bluetooth devices
    """

    run context do
      {res, _code} = System.cmd("bluetoothctl", ["devices"])
      devices =
        res
        |> String.trim()
        |> String.split("\n")
        |> Enum.map(fn x -> x |> String.split(" ", parts: 3) |> Enum.at(2) end)
      IO.puts(devices)
    end
  end
end
