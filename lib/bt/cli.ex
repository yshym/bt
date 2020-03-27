defmodule Bt.CLI do
  use ExCLI.DSL, escript: true
  alias Bt.CLI.Config
  alias Bt.Bluetoothctl

  name "bt"
  description "Bluetooth CLI"
  long_description """
  Handling bluetooth devices from the shell
  """

  def status_by_rc(0), do: IO.ANSI.green() <> "done" <> IO.ANSI.reset()
  def status_by_rc(_rc), do: IO.ANSI.red() <> "failed" <> IO.ANSI.reset()

  def write_to_the_previous_line(line, cursor_position, text) do
    line
    |> IO.ANSI.cursor_up() # move the cursor up to the line we want to modify
    |> Kernel.<>(IO.ANSI.cursor_right(cursor_position)) # move the cursor to specific position
    |> Kernel.<>(text) # write text
    |> Kernel.<>("\r") # move the cursor to the front of the line
    |> Kernel.<>(IO.ANSI.cursor_down(line)) # move the cursor back to the bottom
    |> IO.write()
  end

  command :connect do
    aliases [:con]
    description "Connect device"
    long_description """
    Connect bluetooth device
    """

    argument :alias

    run context do
      selected_adapter_mac = Config.adapter()
      aliases = Config.aliases()

      message = "Trying to connect... "
      IO.puts(message)

      Bluetoothctl.start_link(selected_adapter_mac)
      code = Bluetoothctl.connect(aliases[context.alias])

      write_to_the_previous_line(1, String.length(message), status_by_rc(code))
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
      selected_adapter_mac = Config.adapter()
      aliases = Config.aliases()

      message = "Trying to disconnect... "
      IO.puts(message)

      Bluetoothctl.start_link(selected_adapter_mac)
      code = Bluetoothctl.disconnect(aliases[context.alias])

      write_to_the_previous_line(1, String.length(message), status_by_rc(code))
    end
  end

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

    selected_mac = Config.adapter()

    res
    |> String.split("\n", trim: true)
    |> Enum.reduce(
      [],
      fn x, acc ->
        [_, mac, name, text] = String.split(x, " ")
        map = %{}
          |> Map.put(:mac, mac)
          |> Map.put(:name, name)
          |> Map.put(:is_default, text == "[default]")
          |> Map.put(:is_selected, mac == selected_mac)

        acc ++ [map]
      end
    )
  end

  command :devices do
    aliases [:devs]
    description "List devices"
    long_description """
    List bluetooth devices
    """

    run _context do
      :devices
      |> parse_output()
      |> Enum.map(fn {_mac, name} -> name end)
      |> Enum.join("\n")
      |> IO.puts()
    end
  end

  command :adapter do
    aliases [:controllers]
    description "Manage adapters"
    long_description """
    Manage bluetooth adapters
    """

    argument :action
    argument :name, default: ""

    run context do
      adapters = parse_output(:adapters)

      cond do
        context.action == "ls" or context.action == "list" ->
          adapters
          |> Enum.map(
            fn %{
              mac: _mac,
              name: name,
              is_default: is_default,
              is_selected: is_selected
            } ->
              cond do
                is_default and is_selected -> "#{name} [default] <-"
                is_default -> "#{name} [default]"
                is_selected -> "#{name} <-"
                true -> name
              end
            end
          )
          |> Enum.join("\n")
          |> IO.puts()

        context.action == "select" ->
          mac = adapters
            |> Enum.find(&(&1.name == context.name))
            |> Map.get(:mac)

          Config.write_adapter(mac)
      end
    end
  end

  command :alias do
    description "Manage aliases"
    long_description """
    Manage aliases of devices
    """

    argument :action

    run context do
      devices = parse_output(:devices)
      aliases = Config.aliases()

      cond do
        context.action == "ls" or context.action == "list" ->
          aliases
          |> Enum.map(
            fn {name, mac} ->
              "#{name} -> #{devices[mac]}"
            end
          )
          |> Enum.join("\n")
          |> IO.puts()

        context.action == "add" ->
          # List devices
          devices
          |> Enum.with_index()
          |> Enum.map(fn {{_mac, name}, i} -> "#{i+1}. #{name}" end)
          |> Enum.join("\n")
          |> IO.puts()

          # Choose device
          device_id =
            "Select device: "
            |> IO.gets()
            |> String.trim()
            |> String.to_integer()
            |> Kernel.-(1)

          {device_mac, _device_name} = Enum.at(devices, device_id)

          # Choose alias name
          alias_name =
            "Enter alias: "
            |> IO.gets()
            |> String.trim()

          # Add alias
          aliases
          |> Enum.map(
            fn {name, mac} ->
              if mac == device_mac do
                {alias_name, mac}
              else
                {name, mac}
              end
            end
          )
          |> Enum.into(%{})
          |> Config.write_aliases()
      end
    end
  end
end
