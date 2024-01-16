defmodule DistributedPipeline do

  def start_worker_proxy(worker_type, source, sink) do
    {:ok, worker_pid} = MeasuredBatchedWorker.start_link(worker_type, source, sink)

    # Send worker_pid when asked for it
    receive do
      {:pid_req, ref} ->
        send ref, {:pid_res, worker_pid}
    end

    Utils.wait_for_process(worker_pid)
    {:ok, worker_pid}
  end

  def start_remote_worker(worker_type, source, sink, num) do
    remote = String.to_atom("worker@#{worker_type.name()}_worker_#{num}")
    IO.puts "Remote: #{inspect remote}"
    proxy_pid = Node.spawn_link(remote, DistributedPipeline, :start_worker_proxy, [worker_type, source, sink])
    IO.puts "Proxy pid: #{inspect proxy_pid}"

    # Request the pid of the worker from the proxy on the Node
    send proxy_pid, {:pid_req, self()}
    receive do
      {:pid_res, worker_pid} ->
        {:ok, worker_pid}
    end
  end

  def main do
    {:ok, logger} = CustomMetricsLogger.connect("manager")
    start_time = :os.system_time(:millisecond)
    distributed_ip()
    end_time = :os.system_time(:millisecond)
    duration = end_time - start_time
    IO.puts("Completion time: #{duration} ms")
    MetricsLogger.timing(logger, "completion_time", duration)
    MetricsLogger.close(logger)
  end

  # DistributedPipeline.distributed_ip
  def distributed_ip do
    {:ok, source} = WorkSource.start_link("shared/input", 25)
    IO.puts "Source pid: #{inspect source}"
    {:ok, sink} = WorkSink.start_link()
    IO.puts "Sink pid: #{inspect sink}"
    {:ok, broker_1} = WorkBroker.start_link()
    IO.puts "Broker 1 pid: #{inspect broker_1}"
    {:ok, broker_2} = WorkBroker.start_link()
    IO.puts "Broker 2 pid: #{inspect broker_2}"


    format_workers_replicas = String.to_integer(System.get_env("FORMAT_WORKER_REPLICAS"))
    stage_1_workers = Enum.map(1..format_workers_replicas, fn num ->
      {:ok, pid} = start_remote_worker(FormatWorker, source, broker_1, num)
      GenServer.cast(pid, :start)
      pid
    end)

    resolution_workers_replicas = String.to_integer(System.get_env("RESOLUTION_WORKER_REPLICAS"))
    stage_2_workers = Enum.map(1..resolution_workers_replicas, fn num ->
      {:ok, pid} = start_remote_worker(ResolutionWorker, broker_1, broker_2, num)
      GenServer.cast(pid, :start)
      pid
    end)

    size_workers_replicas = String.to_integer(System.get_env("SIZE_WORKER_REPLICAS"))
    stage_3_workers = Enum.map(1..size_workers_replicas, fn num ->
      {:ok, pid} = start_remote_worker(SizeWorker, broker_2, sink, num)
      GenServer.cast(pid, :start)
      pid
    end)

    workers = stage_1_workers ++ stage_2_workers ++ stage_3_workers

    cleanup(source, workers, [broker_1, broker_2], sink)
  end

  def cleanup(source, workers, brokers, sink) do
    Utils.wait_for_process(sink)

    Enum.each(workers, fn worker ->
      IO.puts "Stopping worker: #{inspect worker}"
      GenServer.call(worker, :stop)
    end)

    Enum.each(brokers, fn broker ->
      IO.puts "Stopping broker: #{inspect broker}"
      GenServer.call(broker, :stop)
    end)

    IO.puts "Stopping Source"
    GenServer.call(source, :stop)
  end

end
