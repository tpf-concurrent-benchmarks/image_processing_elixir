defmodule WorkSource do

  use GenServer

  # the server is initialized with a start num and an end num
  # the server returns an increasing number when asked for work, until it reaches the end num

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init([start_num, end_num]) do
    workers = Map.new()
    {:ok, {start_num, end_num, workers}}
  end

  @impl true
  def handle_cast({:ready, pid}, state) do
    {start_num, end_num, workers } = state
    workers = Map.put(workers, pid, true) #! this is less effective than setting workers by config, but it's more flexible

    if start_num <= end_num do
      GenServer.cast(pid, {:work, start_num})
      {:noreply, {start_num + 1, end_num, workers}}
    else
      GenServer.cast(pid, :no_work)
      {:noreply, {start_num, end_num, workers}}
    end
  end

end
