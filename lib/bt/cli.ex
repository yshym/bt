defmodule Bt.CLI do
  use ExCLI.DSL, escript: true
  alias Bt.CLI.Config

  name "bt"
  description "Bluetooth CLI"
  long_description """
  Handling bluetooth devices from the shell
  """

  command :connect do
    aliases [:con]
    description "Connect device"
    long_description """
    Connect bluetooth device
    """

    argument :alias

    run context do
      aliases = Config.read_aliases()
      {_res, code} = System.cmd("bluetoothctl", ["connect", aliases[context.alias]])
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

    argument :alias

    run context do
      aliases = Config.read_aliases()
      {_res, code} = System.cmd("bluetoothctl", ["disconnect", aliases[context.alias]])
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
        %{},
        fn x, acc ->
          [_, mac, name] = x |> String.split(" ", parts: 3)
          acc |> Map.put(mac, name)
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

  command :aliases do
    description "List aliases"
    long_description """
    List aliases of devices
    """

    run context do
      {res, _code} = System.cmd("bluetoothctl", ["devices"])
      devices = res |> parse_list()
      aliases = Config.read_aliases()

      aliases
      |> Enum.map(
        fn {name, mac} ->
          {name, devices[mac]}
        end
      )
      |> Enum.into(%{})
      |> IO.inspect()
    end
  end
end
