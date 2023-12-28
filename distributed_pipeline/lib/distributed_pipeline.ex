defmodule DistributedPipeline do

  def start_worker_proxy(source, sink) do
    {:ok, worker_pid} = Worker.start_link(source, sink)

    # Send worker_pid when asked for it
    receive do
      {:pid_req, ref} ->
        send ref, {:pid_res, worker_pid}
    end

    Utils.wait_for_process(worker_pid)
    {:ok, worker_pid}
  end

  def start_remote_worker(source, sink) do
    remote = :worker@worker_1
    proxy_pid = Node.spawn_link(remote, DistributedPipeline, :start_worker_proxy, [source, sink])
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
    {:ok, source} = WorkSource.start_link([1,10])
    IO.puts "Source pid: #{inspect source}"
    {:ok, sink} = WorkSink.start_link(nil)
    IO.puts "Sink pid: #{inspect sink}"


    {:ok, worker} = start_remote_worker(source, sink)
    IO.puts "Worker pid: #{inspect worker}"

    GenServer.cast(worker, :start)

    cleanup(source, worker, sink)
  end

  def cleanup(source, worker, sink) do
    Utils.wait_for_process(sink)

    GenServer.stop(worker)
    Utils.wait_for_process(worker)

    GenServer.stop(source)
    Utils.wait_for_process(source)
  end

end

defmodule Hello do
  def say_hello do
    IO.puts "Hello World"
  end

  def say_name(name) do
    IO.puts "Hello #{name}"
  end
end
