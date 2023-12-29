
defmodule Worker do
  @behaviour WorkerBehaviour

  use GenServer

  def start_link(worker_type, source, sink) do
    GenServer.start_link(__MODULE__, {worker_type, source, sink})
  end

  @impl true
  def init({worker_type, source, sink}) do
    pending_work = []
    {:ok, {source, sink, pending_work, worker_type}}
  end

  @impl true
  def handle_cast(:start, {source, sink, _pending, _worker_type} = state) do
    GenServer.call(sink, :register_worker)
    mark_ready(source)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:work, work}, {source, sink, pending, worker_type} = state) do
    res = worker_type.do_work(work)

    receiver = GenServer.call(sink, :request_receiver)
    new_state = case receiver do
      {:pid, pid} ->
        GenServer.cast(pid, {:send, res}) # send result
        state
      :unavailable ->
        {source, sink, [work | pending]}
    end

    if length(pending) < pending_limit() do
      mark_ready(source)
    end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:no_work, {_source, sink, _pending, _worker_type} = state) do
    GenServer.call(sink, :unregister_worker)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:get_work, pid}, {source, sink, pending, worker_type} = state) do

    new_state = case pending do
      [] ->
        # This should only be casted after the sink had denied a receiver, 1:1.
        IO.puts "No work available - This should not happen"
        state
      [work | rest] ->
        GenServer.cast(pid, {:work, work}) # send result
        mark_ready(source)
        {source, sink, rest, worker_type}
    end
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  defp mark_ready(source) do
    GenServer.cast(source, {:ready, self()})
  end

  def pending_limit do
    10
  end

  def do_work(work) do
    IO.puts "Worker #{inspect self()} doing work #{inspect work}"
    :timer.sleep(500)
    work
  end
end
