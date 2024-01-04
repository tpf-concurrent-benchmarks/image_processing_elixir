defmodule WorkSource do

  use GenServer

  def start_link(input_directory, batch_size) do
    GenServer.start_link(__MODULE__, [input_directory, batch_size], name: __MODULE__)
  end

  @impl true
  def init([input_directory, batch_size]) do
    {:ok, walker} = DirWalker.start_link(input_directory)
    {:ok, {walker, batch_size}}
  end

  @impl true
  def handle_cast({:ready, pid}, {walker, batch_size}=state) do
    case DirWalker.next(walker, batch_size) do
      nil ->
        GenServer.cast(pid, :no_work)
      serving_files ->
        GenServer.cast(pid, {:work, serving_files})
    end
    {:noreply, state}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

end
