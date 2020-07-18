defmodule Bt.Bluetoothctl do
  @moduledoc """
  GenServer wrapper around bluetoothctl
  """

  use GenServer
  alias Bt.Parser

  @spec start_link(String.t() | nil) :: term
  def start_link(adapter \\ nil) do
    GenServer.start_link(__MODULE__, adapter, name: __MODULE__)
  end

  @spec init(String.t() | nil) :: {:ok, map}
  def init(adapter) do
    port = Port.open({:spawn, "bluetoothctl"}, [:binary])
    unless is_nil(adapter), do: Port.command(port, "select #{adapter}\n")

    state = %{
      adapter: adapter,
      port: port,
      from: nil,
      last_command: "select"
    }

    {:ok, state}
  end

  def stop do
    GenServer.stop(__MODULE__)
  end

  def devices do
    GenServer.call(__MODULE__, :devices)
  end

  def adapters_data do
    GenServer.call(__MODULE__, :adapters_data)
  end

  @doc """
  Connects a device
  """
  @spec connect(String.t()) :: term
  def connect(device) do
    GenServer.call(__MODULE__, {:connect, device})
  end

  @doc """
  Disconnects a device
  """
  @spec disconnect(String.t()) :: term
  def disconnect(device) do
    GenServer.call(__MODULE__, {:disconnect, device})
  end

  @doc """
  Power on selected adapter
  """
  def on do
    GenServer.cast(__MODULE__, :on)
  end

  @doc """
  Power on an adapter
  """
  def on(adapter) do
    GenServer.cast(__MODULE__, {:on, adapter})
  end

  @doc """
  Power off selected adapter
  """
  def off do
    GenServer.cast(__MODULE__, :off)
  end

  @doc """
  Power off an adapter
  """
  def off(adapter) do
    GenServer.cast(__MODULE__, {:off, adapter})
  end

  @doc """
  Check if adapter is powered
  """
  @spec powered? :: bool
  def powered? do
    GenServer.call(__MODULE__, :powered?)
  end

  @doc """
  Check if device is connected
  """
  @spec connected?(String.t()) :: bool
  def connected?(device) do
    GenServer.call(__MODULE__, {:connected?, device})
  end

  @doc """
  Check if any device is connected
  """
  @spec connected? :: bool
  def connected? do
    GenServer.call(__MODULE__, :connected?)
  end

  @doc """
  Select an adapter
  """
  def select(adapter) do
    GenServer.cast(__MODULE__, {:select, adapter})
  end

  def handle_call(
        {:connect, device},
        from,
        %{port: port} = state
      ) do
    Port.command(port, "connect #{device}\n")

    state =
      state
      |> Map.put(:from, from)
      |> Map.put(:last_command, "connect")

    {:noreply, state}
  end

  def handle_call(
        {:disconnect, device},
        from,
        %{port: port} = state
      ) do
    Port.command(port, "disconnect #{device}\n")

    state =
      state
      |> Map.put(:from, from)
      |> Map.put(:last_command, "disconnect")

    {:noreply, state}
  end

  def handle_call(
        :powered?,
        from,
        %{port: port} = state
      ) do
    Port.command(port, "show\n")

    state =
      state
      |> Map.put(:from, from)
      |> Map.put(:last_command, "show")

    {:noreply, state}
  end

  def handle_call(
        {:connected?, device},
        from,
        %{port: port} = state
      ) do
    Port.command(port, "info #{device}\n")

    state =
      state
      |> Map.put(:from, from)
      |> Map.put(:last_command, "info")

    {:noreply, state}
  end

  def handle_call(
        :connected?,
        from,
        %{port: port} = state
      ) do
    Port.command(port, "info\n")

    state =
      state
      |> Map.put(:from, from)
      |> Map.put(:last_command, "info")

    {:noreply, state}
  end

  def handle_call(:devices, from, %{port: port} = state) do
    Port.command(port, "devices\n")

    state =
      state
      |> Map.put(:from, from)
      |> Map.put(:last_command, "devices")

    {:noreply, state}
  end

  def handle_call(:adapters_data, from, %{port: port} = state) do
    Port.command(port, "list\n")

    state =
      state
      |> Map.put(:from, from)
      |> Map.put(:last_command, "list")

    {:noreply, state}
  end

  def handle_cast(:on, %{port: port} = state) do
    Port.command(port, "power on\n")

    state = Map.put(state, :last_command, "power on")

    {:noreply, state}
  end

  def handle_cast({:on, adapter}, %{port: port} = state) do
    Port.command(port, "select #{adapter}\n")
    Port.command(port, "power on\n")

    state = Map.put(state, :last_command, "power on")

    {:noreply, state}
  end

  def handle_cast(:off, %{port: port} = state) do
    Port.command(port, "power off\n")

    state = Map.put(state, :last_command, "power off")

    {:noreply, state}
  end

  def handle_cast({:off, adapter}, %{port: port} = state) do
    Port.command(port, "select #{adapter}\n")
    Port.command(port, "power off\n")

    state = Map.put(state, :last_command, "power off")

    {:noreply, state}
  end

  def handle_cast({:select, adapter}, %{port: port} = state) do
    Port.command(port, "select #{adapter}\n")

    state = Map.put(state, :last_command, "select")

    {:noreply, state}
  end

  def handle_info({_port, {:data, _data}}, %{last_command: "select"} = state) do
    {:noreply, state}
  end

  def handle_info({_port, {:data, data}}, %{from: from, last_command: last_command} = state) do
    data
    |> String.split(~r"\t|\n|(\r\e\[K)", trim: true)
    |> Enum.each(fn line -> handle_info_line(data, line, from, last_command) end)

    {:noreply, state}
  end

  def handle_info({_port, _msg}, state) do
    {:noreply, state}
  end

  @spec handle_info_line(String.t(), String.t(), GenServer.from(), String.t()) ::
          :ok | map | list | nil
  def handle_info_line(_data, "Failed to connect: " <> _error, from, _last_command) do
    GenServer.reply(from, 1)
  end

  def handle_info_line(_data, "Successful disconnected", from, _last_command) do
    GenServer.reply(from, 0)
  end

  def handle_info_line(_data, "Connection successful", from, _last_command) do
    GenServer.reply(from, 0)
  end

  def handle_info_line(data, "Device " <> _device, from, _last_command) do
    parse_devices(data, from)
  end

  def handle_info_line(data, "Controller " <> _controller, from, "list") do
    # parse_adapters(data, from)
    GenServer.reply(from, data)
  end

  def handle_info_line(_data, "Missing device address argument", from, _last_command) do
    GenServer.reply(from, false)
  end

  def handle_info_line(_data, "Powered: " <> powered, from, _last_command) do
    GenServer.reply(from, powered == "yes")
  end

  def handle_info_line(_data, "Connected: " <> connected, from, _last_command) do
    GenServer.reply(from, connected == "yes")
  end

  def handle_info_line(_data, _line, _from, _last_command) do
    nil
  end

  @spec parse_devices(String.t(), GenServer.from()) :: :ok
  def parse_devices(data, from) do
    devices = Parser.parse_devices(data)

    GenServer.reply(from, devices)
  end

  # @spec parse_adapters(String.t(), GenServer.from()) :: :ok
  # def parse_adapters(data, from) do
  #   adapters =
  #     data
  #     |> Parser.parse_adapters()

  #   # |> Enum.map(fn a ->
  #   #   select(a.mac)

  #   #   Map.put(a, :is_powered, powered?())
  #   # end)

  #   GenServer.reply(from, adapters)
  # end
end
