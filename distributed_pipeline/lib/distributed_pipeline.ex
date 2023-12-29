defmodule DistributedPipeline do

  def start_worker_proxy(worker_type, source, sink) do
    {:ok, worker_pid} = Worker.start_link(worker_type, source, sink)

    # Send worker_pid when asked for it
    receive do
      {:pid_req, ref} ->
        send ref, {:pid_res, worker_pid}
    end

    Utils.wait_for_process(worker_pid)
    {:ok, worker_pid}
  end

  def start_remote_worker(worker_type, source, sink, num) do
    remote = String.to_atom("worker@worker_#{num}")
    proxy_pid = Node.spawn_link(remote, DistributedPipeline, :start_worker_proxy, [worker_type, source, sink])
    IO.puts "Proxy pid: #{inspect proxy_pid}"

    # Request the pid of the worker from the proxy on the Node
    send proxy_pid, {:pid_req, self()}
    receive do
      {:pid_res, worker_pid} ->
        {:ok, worker_pid}
    end
  end

  # DistributedPipeline.distributed_count
  def distributed_count do
    {:ok, source} = WorkSource.start_link([1,100])
    IO.puts "Source pid: #{inspect source}"
    {:ok, sink} = WorkSink.start_link(nil)
    IO.puts "Sink pid: #{inspect sink}"


    {:ok, worker_1} = start_remote_worker(FastWorker, source, sink, 1)
    IO.puts "Worker 1 pid: #{inspect worker_1}"
    {:ok, worker_2} = start_remote_worker(FastWorker, source, sink, 2)
    IO.puts "Worker 2 pid: #{inspect worker_2}"
    {:ok, worker_3} = start_remote_worker(FastWorker, source, sink, 3)
    IO.puts "Worker 2 pid: #{inspect worker_3}"

    GenServer.cast(worker_1, :start)
    GenServer.cast(worker_2, :start)
    GenServer.cast(worker_3, :start)

    cleanup(source, [worker_1, worker_2, worker_3], sink)
  end

  def cleanup(source, workers, sink) do
    Utils.wait_for_process(sink)

    Enum.each(workers, fn worker ->
      IO.puts "Stopping worker: #{inspect worker}"
      GenServer.call(worker, :stop)
    end)

    IO.puts "Stopping Source"
    GenServer.call(source, :stop)
  end

end
