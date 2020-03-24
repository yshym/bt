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
      {_res, code} = System.cmd("bluetoothctl", ["connect", context.device])
      if code == 0 do
        IO.puts("Device was successfully connected")
      else
        IO.puts("Failed to connect")
      end
    end
  end

  command :disconnect do
    aliases [:dcon]
    description "Disconnect device"
    long_description """
    Disconnect bluetooth device
    """

    argument :device

    run context do
      {_res, code} = System.cmd("bluetoothctl", ["disconnect", context.device])
      if code == 0 do
        IO.puts("Device was successfully disconnected")
      else
        IO.puts("Failed to disconnect")
      end
    end
  end

  def parse_list(list) do
    list
      |> String.trim()
      |> String.split("\n")
      |> Enum.reduce(
        [],
        fn x, acc ->
          [_, mac, name] = x |> String.split(" ", parts: 3)
          acc ++ [%{} |> Map.put(:mac, mac) |> Map.put(:name, name)]
        end
      )
  end

  command :devices do
    aliases [:devs]
    description "List devices"
    long_description """
    List bluetooth devices
    """

    run context do
      {res, _code} = System.cmd("bluetoothctl", ["devices"])
      res |> parse_list() |> IO.inspect()
    end
  end

  command :adapters do
    aliases [:controllers]
    description "List adapters"
    long_description """
    List bluetooth adapters
    """

    run context do
      {res, _code} = System.cmd("bluetoothctl", ["list"])
      res |> parse_list() |> IO.inspect()
    end
  end
end
