defmodule Bt.CLI do
  use ExCLI.DSL, escript: true
  alias Bt.{CLI.Config, Bluetoothctl, Parser}

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

      if context.alias in Map.keys(aliases) do
        message = "Trying to connect... "
        IO.puts(message)

        Bluetoothctl.start_link(selected_adapter_mac)
        code = Bluetoothctl.connect(aliases[context.alias])

        write_to_the_previous_line(1, String.length(message), status_by_rc(code))
      else
        IO.puts("Alias '#{context.alias}' does not exist. Use 'bt alias ls' to list aliases")
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
      selected_adapter_mac = Config.adapter()
      aliases = Config.aliases()


      if context.alias in Map.keys(aliases) do
        message = "Trying to disconnect... "
        IO.puts(message)

        Bluetoothctl.start_link(selected_adapter_mac)
        code = Bluetoothctl.disconnect(aliases[context.alias])

        write_to_the_previous_line(1, String.length(message), status_by_rc(code))
      else
        IO.puts("Alias '#{context.alias}' does not exist. Use 'bt alias ls' to list aliases")
      end
    end
  end

  command :devices do
    aliases [:devs]
    description "List devices"
    long_description """
    List bluetooth devices
    """

    run _context do
      :devices
      |> Parser.parse_output()
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

      cond do
        context.action == "ls" or context.action == "list" ->
          adapters = Parser.parse_output(:adapters)

          adapters
          |> Enum.map(
            fn %{
              mac: _mac,
              name: name,
              is_selected: is_selected,
              is_powered: is_powered
            } ->
              on = IO.ANSI.green() <> "" <> IO.ANSI.reset()
              off = IO.ANSI.white() <> "" <> IO.ANSI.reset()

              name
              |> Kernel.<>(if is_powered, do: " #{on}", else: " #{off}")
              |> Kernel.<>(if is_selected, do: " <-", else: "")
            end
          )
          |> Enum.join("\n")
          |> IO.puts()

        context.action == "select" ->
          adapters = Parser.parse_output(:adapters)

          adapter = Enum.find(adapters, &(&1.name == context.name))

          if is_nil(adapter) do
            IO.puts("Adapter '#{context.name}' does not exist. Use 'bt adapter ls' to list adapters")
          else
            mac = Map.get(adapter, :mac)

            Config.write_adapter(mac)
          end

        context.action == "on" or context.action == "off" ->
          selected_mac = Config.adapter()

          Bluetoothctl.start_link(selected_mac)
          apply(Bluetoothctl, String.to_atom(context.action), [])

        true -> IO.puts("Action '#{context.action}' does not exist")
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
      devices = Parser.parse_output(:devices)
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

        true -> IO.puts("Action '#{context.action}' does not exist")
      end
    end
  end
end
