defmodule Bt.Bluetoothctl do
  use GenServer

  def start_link(adapter \\ nil) do
    GenServer.start_link(__MODULE__, adapter, name: __MODULE__)
  end

  def init(adapter) do
    port = Port.open({:spawn, "bluetoothctl"}, [:binary])
    unless is_nil(adapter), do: Port.command(port, "select #{adapter}\n")

    state = %{
      adapter: adapter,
      port: port,
      from: nil
    }

    {:ok, state}
  end

  def connect(device) do
    GenServer.call(__MODULE__, {:connect, device})
  end

  def disconnect(device) do
    GenServer.call(__MODULE__, {:disconnect, device})
  end

  def on do
    GenServer.cast(__MODULE__, :on)
  end

  def off do
    GenServer.cast(__MODULE__, :off)
  end

  def powered? do
    GenServer.call(__MODULE__, :powered?)
  end

  def connected?(device) do
    GenServer.call(__MODULE__, {:connected?, device})
  end
  def connected? do
    GenServer.call(__MODULE__, :connected?)
  end

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

  def handle_cast(:on, %{port: port} = state) do
    Port.command(port, "power on\n")

    {:noreply, state}
  end
  def handle_cast(:off, %{port: port} = state) do
    Port.command(port, "power off\n")

    {:noreply, state}
  end
  def handle_cast({:select, adapter}, %{port: port} = state) do
    Port.command(port, "select #{adapter}\n")

    {:noreply, state}
  end

  def handle_info({_port, {:data, data}}, %{from: from} = state) do
    data
    |> String.split(~r"\t|\n|(\r\e\[K)", trim: true)
    |> Enum.each(
      fn line ->
        case line do
          "Failed to connect: " <> _error ->
            GenServer.reply(from, 1)

          "Successful disconnected" ->
            GenServer.reply(from, 0)

          "Connection successful" ->
            GenServer.reply(from, 0)

          "Powered: " <> state ->
            GenServer.reply(from, state == "yes")

          "Missing device address argument" ->
            GenServer.reply(from, false)

          "Connected: " <> state ->
            GenServer.reply(from, state == "yes")

          _ -> nil
        end
      end
    )

    {:noreply, state}
  end
  def handle_info({_port, _msg}, state) do
    {:noreply, state}
  end
end
