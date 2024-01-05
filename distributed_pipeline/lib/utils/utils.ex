defmodule Utils do
  def wait_for_process(pid) do
    Process.monitor(pid)
    receive do
      {:DOWN, _ref, :process, ^pid, _reason} -> :ok
    end
  end
end
