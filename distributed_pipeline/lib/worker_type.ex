defmodule WorkerBehaviour do
  @callback do_work(any()) :: any()
end

defmodule SlowWorker do
  @behaviour WorkerBehaviour

  def do_work(work) do
    # IO.puts "Slow worker #{inspect self()} doing work #{inspect work}"
    :timer.sleep(500)
    work
  end
end

defmodule FastWorker do
  @behaviour WorkerBehaviour

  def do_work(work) do
    IO.puts "Fast worker #{inspect self()} doing work #{inspect work}"
    work
  end
end
