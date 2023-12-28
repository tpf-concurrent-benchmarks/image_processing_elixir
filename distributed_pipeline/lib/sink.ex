defmodule WorkSink do

  use GenServer

  # the server is initialized with a start num and an end num
  # the server returns an increasing number when asked for work, until it reaches the end num

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    finished_workers = Map.new()
    {:ok, {finished_workers}}
  end

  @impl true
  def handle_call(:request_receiver, _from, state) do
    {:reply, {:pid, self()}, state}
  end

  @impl true
  def handle_cast({:send, data}, state) do
    IO.puts "Sink received: #{data}"
    {:noreply, state}
  end

  @impl true
  def handle_call(:register_worker, pid, {finished_workers}) do
    IO.puts "Registering worker #{inspect pid}"
    {:reply, :ok, {Map.put(finished_workers, pid, false)}}
  end

  @impl true
  def handle_call(:unregister_worker, pid, {finished_workers}) do
    IO.puts "Unregistering worker #{inspect pid}"
    new_workers = Map.put(finished_workers, pid, true)

    if Map.values(new_workers) |> Enum.all?(& &1) do
      IO.puts "All workers finished"
      {:stop, :normal, :ok, {new_workers}}
    else
      {:reply, :ok, {new_workers}}
    end
  end



end
