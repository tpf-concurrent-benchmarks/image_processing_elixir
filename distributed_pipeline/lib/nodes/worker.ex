defmodule BaseWorker do
  defmacro __using__(_) do
    quote do
      use GenServer

      def start_link(worker_type, source, sink) do
        GenServer.start_link(__MODULE__, {worker_type, source, sink})
      end

      @impl true
      def init({worker_type, source, sink}) do
        pending_work = []
        other = nil
        {:ok, {source, sink, pending_work, worker_type, false, other}}
      end
      defoverridable init: 1

      @impl true
      def handle_cast(:start, {source, sink, _pending, _worker_type, _done, _other} = state) do
        GenServer.call(sink, :register_worker)
        mark_ready(source)
        {:noreply, state}
      end

      @impl true
      def handle_cast({:work, work}, {source, sink, pending, worker_type, done, other} = state) do
        res = do_work(worker_type, work, other)

        receiver = GenServer.call(sink, :request_receiver)
        new_state = case receiver do
          {:pid, pid} ->
            GenServer.cast(pid, {:work, res}) # send result
            state
          :unavailable ->
            {source, sink, [work | pending], worker_type, done, other}
        end

        if length(pending) < pending_limit() do
          not done && mark_ready(source)
        end

        {:noreply, new_state}
      end

      @impl true
      def handle_cast(:no_work, {source, sink, pending, worker_type, done, other}) do
        not done && GenServer.call(sink, :unregister_worker)
        {:noreply, {source, sink, pending, worker_type, true, other}}
      end

      @impl true
      def handle_cast({:get_work, pid}, {source, sink, pending, worker_type, done, other} = state) do

        new_state = case pending do
          [] ->
            state
          [work | rest] ->
            GenServer.cast(pid, {:work, work}) # send result
            not done && mark_ready(source)
            {source, sink, rest, worker_type, done, other}
        end
        {:noreply, new_state}
      end

      @impl true
      def handle_call(:stop, _from, {_source, _sink, _pending, _worker_type, _done, other} = state) do
        cleanup(other)
        {:stop, :normal, :ok, state}
      end

      defp mark_ready(source) do
        GenServer.cast(source, {:ready, self()})
      end

      def pending_limit do
        10
      end

      defp do_work(_worker_type, _work, _other), do: raise "Not implemented"
      defoverridable do_work: 3

      defp cleanup(_other) do
        :ok
      end
      defoverridable cleanup: 1
    end
  end
end

defmodule Worker do
  use BaseWorker

  defp do_work(worker_type, work, _other) do
    worker_type.do_work(work)
  end
end

defmodule BatchedWorker do
  use BaseWorker

  defp do_work(worker_type, work, _other) do
    Enum.map(work, &worker_type.do_work/1)
  end
end

defmodule MeasuredBatchedWorker do
  use BaseWorker

  def init({worker_type, source, sink}) do
    pending_work = []
    replica = System.get_env("REPLICA")
    {:ok, logger} = CustomMetricsLogger.connect(worker_type.name, replica)
    {:ok, {source, sink, pending_work, worker_type, false, logger}}
  end

  def do_work_and_measure( worker_type, work, logger ) do
    start_time = :os.system_time(:millisecond)
    res = worker_type.do_work(work)
    end_time = :os.system_time(:millisecond)
    duration = end_time - start_time
    MetricsLogger.timing(logger, "work_time", duration)
    MetricsLogger.increment(logger, "results_produced")
    res
  end

  defp do_work(worker_type, work, logger) do
    Enum.map(work, &do_work_and_measure(worker_type, &1, logger))
  end

  defp cleanup(logger) do
    MetricsLogger.close(logger)
  end

end
