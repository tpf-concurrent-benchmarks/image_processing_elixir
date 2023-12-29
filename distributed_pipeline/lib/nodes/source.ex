defmodule WorkSource do

  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init([start_num, end_num]) do
    {:ok, {start_num, end_num}}
  end

  @impl true
  def handle_cast({:ready, pid}, {start_num, end_num}) do

    if start_num <= end_num do
      GenServer.cast(pid, {:work, start_num})
      {:noreply, {start_num + 1, end_num}}
    else
      GenServer.cast(pid, :no_work)
      {:noreply, {start_num, end_num}}
    end

  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

end
