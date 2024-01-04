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

  def node_n(num) do
    max_num = 3 # number worker replicas
    rem(num, max_num) + 1
  end

  # DistributedPipeline.distributed_count
  def distributed_count do
    {:ok, source} = WorkSource.start_link("shared/input", 5)
    IO.puts "Source pid: #{inspect source}"
    {:ok, sink} = WorkSink.start_link()
    IO.puts "Sink pid: #{inspect sink}"
    {:ok, broker_1} = WorkBroker.start_link()
    IO.puts "Broker 1 pid: #{inspect broker_1}"
    {:ok, broker_2} = WorkBroker.start_link()
    IO.puts "Broker 2 pid: #{inspect broker_2}"


    stage_1_workers = Enum.map(1..2, fn num ->
      {:ok, pid} = start_remote_worker(FormatWorker, source, broker_1, node_n(num))
      GenServer.cast(pid, :start)
      pid
    end)

    stage_2_workers = Enum.map(1..2, fn num ->
      {:ok, pid} = start_remote_worker(ResolutionWorker, broker_1, broker_2, node_n(num))
      GenServer.cast(pid, :start)
      pid
    end)

    stage_3_workers = Enum.map(1..2, fn num ->
      {:ok, pid} = start_remote_worker(SizeWorker, broker_2, sink, node_n(num))
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
