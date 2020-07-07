defmodule Bt.CLI do
  @moduledoc """
  Bluetooth command line interface
  """

  use ExCLI.DSL, escript: true
  alias Bt.{Bluetoothctl, CLI.Config, Wrapper, Parser}

  name("bt")
  description("Bluetooth CLI")

  long_description("""
  Handling bluetooth devices from the shell
  """)

  @doc """
  Return status of the command based on the return code
  """
  @spec status_by_rc(0..255) :: String.t()
  def status_by_rc(0), do: IO.ANSI.green() <> "done" <> IO.ANSI.reset()
  def status_by_rc(_rc), do: IO.ANSI.red() <> "failed" <> IO.ANSI.reset()

  @doc """
  Write text to the previous line
  """
  @spec write_to_the_previous_line(integer, integer, String.t()) :: :ok
  def write_to_the_previous_line(line, cursor_position, text) do
    line
    # move the cursor up to the line we want to modify
    |> IO.ANSI.cursor_up()
    # move the cursor to specific position
    |> Kernel.<>(IO.ANSI.cursor_right(cursor_position))
    # write text
    |> Kernel.<>(text)
    # move the cursor to the front of the line
    |> Kernel.<>("\r")
    # move the cursor back to the bottom
    |> Kernel.<>(IO.ANSI.cursor_down(line))
    |> IO.write()
  end

  command :connect do
    aliases([:con])
    description("Connect device")

    long_description("""
    Connect bluetooth device
    """)

    argument(:alias)

    run context do
      selected_adapter_mac = Config.adapter()
      aliases = Config.aliases()

      if selected_adapter_mac == "" do
        IO.puts("Adapter is not selected. 'bt adapter select <adapter>' to choose one")
      else
        if context.alias in Map.keys(aliases) do
          message = "Trying to connect... "
          IO.puts(message)

          Bluetoothctl.start_link(selected_adapter_mac)
          is_connected = Bluetoothctl.connected?()

          code =
            if is_connected do
              1
            else
              Wrapper.with_exit_code(fn -> Bluetoothctl.connect(aliases[context.alias]) end)
            end

          status = status_by_rc(code)
          issue = if is_connected, do: "Already connected"

          write_to_the_previous_line(
            1,
            String.length(message),
            if(issue, do: "#{status} (#{issue})", else: status)
          )
        else
          IO.puts("Alias '#{context.alias}' does not exist. Use 'bt alias ls' to list aliases")
        end
      end
    end
  end

  command :disconnect do
    aliases([:dcon])
    description("Disconnect device")

    long_description("""
    Disconnect bluetooth device
    """)

    argument(:alias)

    run context do
      selected_adapter_mac = Config.adapter()
      aliases = Config.aliases()

      if selected_adapter_mac == "" do
        IO.puts("Adapter is not selected. 'bt adapter select <adapter>' to choose one")
      else
        if context.alias in Map.keys(aliases) do
          message = "Trying to disconnect... "
          IO.puts(message)

          Bluetoothctl.start_link(selected_adapter_mac)
          code = Wrapper.with_exit_code(fn -> Bluetoothctl.disconnect(aliases[context.alias]) end)

          write_to_the_previous_line(1, String.length(message), status_by_rc(code))
        else
          IO.puts("Alias '#{context.alias}' does not exist. Use 'bt alias ls' to list aliases")
        end
      end
    end
  end

  command :reconnect do
    aliases([:rcon])
    description("Reconnect device")

    long_description("""
    Reconnect bluetooth device
    """)

    argument(:alias)

    run context do
      selected_adapter_mac = Config.adapter()
      aliases = Config.aliases()

      if selected_adapter_mac == "" do
        IO.puts("Adapter is not selected. 'bt adapter select <adapter>' to choose one")
      else
        if context.alias in Map.keys(aliases) do
          message = "Trying to reconnect... "
          IO.puts(message)

          mac = aliases[context.alias]

          Bluetoothctl.start_link(selected_adapter_mac)

          d_code = Wrapper.with_exit_code(fn -> Bluetoothctl.disconnect(mac) end)
          c_code = Wrapper.with_exit_code(fn -> Bluetoothctl.connect(mac) end)

          write_to_the_previous_line(1, String.length(message), status_by_rc(max(d_code, c_code)))
        else
          IO.puts("Alias '#{context.alias}' does not exist. Use 'bt alias ls' to list aliases")
        end
      end
    end
  end

  command :devices do
    aliases([:devs])
    description("List devices")

    long_description("""
    List bluetooth devices
    """)

    run _context do
      selected_adapter_mac = Config.adapter()

      Bluetoothctl.start_link(selected_adapter_mac)

      Bluetoothctl.devices()
      |> Enum.map(fn {_mac, name} -> name end)
      |> Enum.join("\n")
      |> IO.puts()
    end
  end

  command :adapter do
    aliases([:controllers])
    description("Manage adapters")

    long_description("""
    Manage bluetooth adapters
    """)

    argument(:action)
    argument(:name, default: "")

    run context do
      adapters = Parser.parse_adapters()

      cond do
        context.action == "ls" or context.action == "list" ->
          adapters
          |> Enum.map(fn %{
                           mac: _mac,
                           name: name,
                           is_selected: is_selected,
                           is_powered: is_powered
                         } ->
            on = IO.ANSI.green() <> "●" <> IO.ANSI.reset()
            off = IO.ANSI.white() <> "●" <> IO.ANSI.reset()

            name
            |> Kernel.<>(if is_powered, do: " #{on}", else: " #{off}")
            |> Kernel.<>(if is_selected, do: " <-", else: "")
          end)
          |> Enum.join("\n")
          |> IO.puts()

        context.action == "select" ->
          adapter = Enum.find(adapters, &(&1.name == context.name))

          if is_nil(adapter) do
            IO.puts(
              "Adapter '#{context.name}' does not exist. Use 'bt adapter ls' to list adapters"
            )
          else
            mac = Map.get(adapter, :mac)

            Config.write_adapter(mac)
          end

        context.action == "on" or context.action == "off" ->
          selected_mac = Config.adapter()
          Bluetoothctl.start_link(selected_mac)
          apply(Bluetoothctl, String.to_atom(context.action), [])

        true ->
          IO.puts("Action '#{context.action}' does not exist")
      end
    end
  end

  command :alias do
    description("Manage aliases")

    long_description("""
    Manage aliases of devices
    """)

    argument(:action)

    run context do
      selected_adapter_mac = Config.adapter()
      Bluetoothctl.start_link(selected_adapter_mac)
      devices = Bluetoothctl.devices()
      aliases = Config.aliases()

      cond do
        context.action == "ls" or context.action == "list" ->
          aliases
          |> Enum.map(fn {name, mac} ->
            "#{name} -> #{devices[mac]}"
          end)
          |> Enum.join("\n")
          |> IO.puts()

        context.action == "add" ->
          # List devices
          devices
          |> Enum.with_index()
          |> Enum.map(fn {{_mac, name}, i} -> "#{i + 1}. #{name}" end)
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
          Config.add_alias(device_mac, alias_name)

        true ->
          IO.puts("Action '#{context.action}' does not exist")
      end
    end
  end
end
