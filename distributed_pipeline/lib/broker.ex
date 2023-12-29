defmodule WorkBroker do

  use GenServer

  def start_link() do
    start_link(nil)
  end

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  @impl true
  def init(_arg) do
    workers_with_pending_results = [] # These give work
    workers_ready_for_work = [] # These receive work
    finished_workers = Map.new()
    {:ok, {workers_with_pending_results, workers_ready_for_work, finished_workers, false}}
  end

  @impl true
  def handle_call(:register_worker, {pid, _ref}, {w_pending, w_ready, w_finished, all_finished}) do
    IO.puts "Registering worker #{inspect pid}"
    new_finished = Map.put(w_finished, pid, false)
    {:reply, :ok, {w_pending, w_ready, new_finished, false}}
  end


  @impl true
  def handle_call(:unregister_worker, {pid, _ref}, {w_pending, w_ready, w_finished, all_finished}) do
    IO.puts "Unregistering worker #{inspect pid}"
    new_finished = Map.put(w_finished, pid, true)
    IO.puts "Finished workers: #{inspect new_finished}"

    if Map.values(new_finished) |> Enum.all?(& &1) do
      Enum.each(w_ready, fn worker ->
        GenServer.cast(worker, :no_work)
      end)
      {:reply, :ok, {w_pending, w_ready, new_finished, true}}
    else
      {:reply, :ok, {w_pending, w_ready, new_finished, false}}
    end
  end

  @impl true
  def handle_call(:request_receiver, {pid, _res}, {w_pending, w_ready, w_finished, all_finished}) do
    if length(w_ready) > 0 do
      {:reply, {:pid, hd(w_ready)}, {w_pending, tl(w_ready), w_finished, all_finished}}
    else
      {:reply, :unavailable, {[pid | w_pending], w_ready, w_finished, all_finished}}
    end
  end

  @impl true
  def handle_cast({:ready, pid}, {w_pending, w_ready, w_finished, all_finished}) do

    if length(w_pending) > 0 do
      pending_res_worker = hd(w_pending)
      GenServer.cast(pending_res_worker, {:get_work, pid})
      {:noreply, {tl(w_pending), w_ready, w_finished, all_finished}}
    else
      if all_finished do
        GenServer.cast(pid, :no_work)
      end
      {:noreply, {w_pending, [pid | w_ready], w_finished, all_finished}}
    end

  end


  @impl true
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

end
