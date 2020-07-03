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

  def devices do
    GenServer.call(__MODULE__, :devices)
  end

  def adapters do
    GenServer.call(__MODULE__, :adapters)
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
  Power on an adapter
  """
  def on do
    GenServer.cast(__MODULE__, :on)
  end

  @doc """
  Power off an adapter
  """
  def off do
    GenServer.cast(__MODULE__, :off)
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

    state = Map.put(state, :from, from)

    {:noreply, state}
  end

  def handle_call(
        {:disconnect, device},
        from,
        %{port: port} = state
      ) do
    Port.command(port, "disconnect #{device}\n")

    state = Map.put(state, :from, from)

    {:noreply, state}
  end

  def handle_call(
        :powered?,
        from,
        %{port: port} = state
      ) do
    Port.command(port, "show\n")

    state = Map.put(state, :from, from)

    {:noreply, state}
  end

  def handle_call(
        {:connected?, device},
        from,
        %{port: port} = state
      ) do
    Port.command(port, "info #{device}\n")

    state = Map.put(state, :from, from)

    {:noreply, state}
  end

  def handle_call(
        :connected?,
        from,
        %{port: port} = state
      ) do
    Port.command(port, "info\n")

    state = Map.put(state, :from, from)

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

  def handle_call(:adapters, from, %{port: port} = state) do
    Port.command(port, "list\n")

    state =
      state
      |> Map.put(:from, from)
      |> Map.put(:last_command, "list")

    {:noreply, state}
  end

  def handle_cast(:on, %{port: port} = state) do
    Port.command(port, "power on\n")

    {:noreply, state}
  end

  def handle_cast(:off, %{port: port} = state) do
    Port.command(port, "power off\n")

    {:noreply, state}
  end

  def handle_cast({:select, adapter}, %{port: port} = state) do
    Port.command(port, "select #{adapter}\n", [:force])

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

  @spec parse_devices(String.t(), GenServer.from()) :: :ok
  def parse_devices(data, from) do
    devices = Parser.parse_devices(data)

    GenServer.reply(from, devices)
  end

  @spec parse_adapters(String.t(), GenServer.from()) :: :ok
  def parse_adapters(data, from) do
    adapters =
      data
      |> Parser.parse_adapters()

    # |> Enum.map(fn a ->
    #   select(a.mac)

    #   Map.put(a, :is_powered, powered?())
    # end)

    GenServer.reply(from, adapters)
  end

  def handle_info_line(data, line, from, last_command) do
    case line do
      "Device " <> _device ->
        parse_devices(data, from)

      "Controller " <> _controller ->
        if last_command == "list", do: parse_adapters(data, from), else: nil

      "Failed to connect: " <> _error ->
        GenServer.reply(from, 1)

      "Successful disconnected" ->
        GenServer.reply(from, 0)

      "Connection successful" ->
        GenServer.reply(from, 0)

      "Powered: " <> powered ->
        GenServer.reply(from, powered == "yes")

      "Missing device address argument" ->
        GenServer.reply(from, false)

      "Connected: " <> connected ->
        GenServer.reply(from, connected == "yes")

      _ ->
        nil
    end
  end
end
