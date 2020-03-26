defmodule Bt.Bluetoothctl do
  use GenServer

  def start_link(adapter) do
    GenServer.start_link(__MODULE__, adapter, name: __MODULE__)
  end

  def init(adapter) do
    port = Port.open({:spawn, "bluetoothctl"}, [:binary])
    Port.command(port, "select #{adapter}\n")

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

  def handle_call(
    {:connect, device},
    from,
    %{port: port} = state
  ) do
    Port.command(port, "connect #{device}\n")

    state = state |> Map.put(:from, from)

    {:noreply, state}
  end
  def handle_call(
    {:disconnect, device},
    from,
    %{port: port} = state
  ) do
    Port.command(port, "disconnect #{device}\n")

    state = state |> Map.put(:from, from)

    {:noreply, state}
  end

  def handle_info({port, {:data, data}}, %{from: from} = state) do
    data
    |> String.split(~r"\n|(\r\e\[K)", trim: true)
    |> Enum.each(
      fn line ->
        case line do
          "Failed to connect: " <> _error ->
            GenServer.reply(from, 1)
            Port.close(port)

          "Successful disconnected" ->
            GenServer.reply(from, 0)
            Port.close(port)

          "Connection successful" ->
            GenServer.reply(from, 0)
            Port.close(port)

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
