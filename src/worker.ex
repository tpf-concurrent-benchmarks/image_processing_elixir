defmodule WorkSource do

  use GenServer

  # the server is initialized with a start num and an end num
  # the server returns an increasing number when asked for work, until it reaches the end num

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init([start_num, end_num]) do
    {:ok, {start_num, end_num}}
  end

  @impl true
  def handle_call(:get_work, _from, state) do
    {start_num, end_num} = state

    # wait a second before returning work
    :timer.sleep(1000)

    if start_num <= end_num do
      {:reply, start_num, {start_num + 1, end_num}}
    else
      {:reply, :no_work, state}
    end
  end

end

defmodule Worker do

  use GenServer

  # the worker is initialized with a server pid
  # the worker asks the server for work, and then does the work
  # the worker asks for more work until the server says there is no more work

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(server_pid) do
    {:ok, server_pid}
  end

  @impl true
  def handle_call(:start, _from, server_pid) do
    ask_for_work(server_pid)
    {:reply, :ok, server_pid}
  end

  @impl true
  def handle_cast(:start, server_pid) do
    ask_for_work(server_pid)
    {:noreply, server_pid}
  end

  def ask_for_work(server_pid) do
    res = GenServer.call(server_pid, :get_work)
    case res do
      :no_work -> shutdown()
      work ->
        do_work(work)
        ask_for_work(server_pid)
    end
  end

  def do_work(work) do
    IO.puts "Doing work: #{work}"
  end

  def shutdown() do
    IO.puts "No more work. Shutting down."
    # terminate the process
    Process.exit(self(), :shutdown)
  end
end

defmodule Utils do
  def wait_for_process(pid) do
    Process.monitor(pid)
    receive do
      {:DOWN, _ref, :process, ^pid, _reason} -> :ok
    end
  end
end
