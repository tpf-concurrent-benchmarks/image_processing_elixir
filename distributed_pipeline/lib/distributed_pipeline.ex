defmodule DistributedPipeline do
  # -> can run modules
  # DistributedPipeline.local_count
  def local_count do
    #{:ok, server_pid} = GenServer.start_link(WorkSource, [1,10])
    {:ok, server_pid} = WorkSource.start_link([1,10])
    {:ok, worker_pid} = Worker.start_link(server_pid)
    GenServer.call(worker_pid, :start)
    GenServer.stop(worker_pid)
    Utils.wait_for_process(worker_pid)
  end

  # -> remote exists
  def ping_remote do
    remote = :worker@worker_1
    res = Node.ping(remote)
    IO.puts "Ping result: #{inspect res}"
  end

  def say_hello do
    IO.puts "Hello from #{inspect Node.self()}"
  end

  # -> can call modules on distributed nodes
  # DistributedPipeline.distributed_hello
  def distributed_hello do
    remote = :worker@worker_1
    Node.spawn_link(remote, &Hello.say_hello/0)
  end

  # -> can call modules on distributed nodes with arguments
  # DistributedPipeline.distributed_hello_name("John")
  def distributed_hello_name(name) do
    remote = :worker@worker_1
    Node.spawn_link(remote, Hello, :say_name, [name])
  end

  def start_worker_proxy(server_pid) do
    {:ok, worker_pid} = Worker.start_link(server_pid)

    receive do
      {:pid_req, ref} ->
        send ref, {:pid_res, worker_pid}
    end

    # wait for the worker to stop
    Utils.wait_for_process(worker_pid)
    {:ok, worker_pid}
  end

  def start_remote_worker(server_pid) do
    # {:ok, worker_pid} = GenServer.start_link(Worker, server_pid)
    remote = :worker@worker_1
    proxy_pid = Node.spawn_link(remote, DistributedPipeline, :start_worker_proxy, [server_pid])
    IO.puts "Proxy pid: #{inspect proxy_pid}"

    send proxy_pid, {:pid_req, self()}
    receive do
      {:pid_res, worker_pid} ->
        {:ok, worker_pid}
    end
  end

  # DistributedPipeline.distributed_count
  def distributed_count do
    {:ok, server_pid} = WorkSource.start_link([1,10])
    IO.puts "Server pid: #{inspect server_pid}"
    {:ok, worker_pid} = start_remote_worker(server_pid)
    IO.puts "Worker pid: #{inspect worker_pid}"

    # GenServer.call(worker_pid, :start, :infinity)
    GenServer.cast(worker_pid, :start)
    Utils.wait_for_process(worker_pid)
    GenServer.stop(server_pid)
    Utils.wait_for_process(server_pid)
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
