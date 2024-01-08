defmodule WorkSink do

  use GenServer

  def start_link() do
    start_link(nil)
  end

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    finished_workers = Map.new()
    {:ok, {finished_workers, 0}}
  end

  @impl true
  def handle_call(:request_receiver, _from, state) do
    {:reply, {:pid, self()}, state}
  end

  @impl true
  def handle_call(:register_worker, {pid, _ref}, {finished_workers, results}) do
    IO.puts "Registering worker #{inspect pid}"
    {:reply, :ok, {Map.put(finished_workers, pid, false), results}}
  end

  @impl true
  def handle_call(:unregister_worker, {pid, _ref}, {finished_workers, results}) do
    IO.puts "Unregistering worker #{inspect pid}"
    new_workers = Map.put(finished_workers, pid, true)
    IO.puts "Finished workers: #{inspect new_workers}"

    if Map.values(new_workers) |> Enum.all?(& &1) do
      finish_message(results)
      GenServer.cast(self(), :stop)
    end
    {:reply, :ok, {new_workers, results}}
  end

  @impl true
  def handle_call(:stop, _from, {_fw, results}=state) do
    IO.puts "Sink finished with #{results} results"
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_cast(:stop, {_fw, results}=state) do
    IO.puts "Sink finished with #{results} results"
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:work, _data}, {fw, results}) do
    # IO.puts "Sink received: #{data}"
    {:noreply, {fw, results+1}}
  end

  defp finish_message(results) do
    message = "### Sink finished with: #{results} results ###"
    border = String.duplicate("#", String.length(message))

    IO.puts border
    IO.puts message
    IO.puts border
  end

end
