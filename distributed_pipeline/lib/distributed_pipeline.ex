defmodule DistributedPipeline do
  def hello do
    {:ok, server_pid} = GenServer.start_link(WorkSource, [1,10])
    {:ok, worker_pid} = GenServer.start_link(Worker, server_pid)
    GenServer.call(worker_pid, :start)
    GenServer.stop(worker_pid)
    Utils.wait_for_process(worker_pid)
  end
end
