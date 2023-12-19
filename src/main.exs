defmodule Messages do
  def sender(receiver, file_name) do
    spawn_link(fn -> send_messages(receiver, file_name) end)
  end

  defp send_messages(receiver, file_name) do
    file_name
    |> File.stream!()
    |> Enum.each(&send_message(receiver, &1))

    send(receiver, {self(), :stop})
  end

  defp send_message(receiver, message) do
    send(receiver, {self(), String.trim(message)})
  end

  def receiver do
    spawn_link(fn -> receive_messages() end)
  end

  defp receive_messages do
    receive do
      {_sender, :stop} ->
        IO.puts "Received stop message. Exiting."

      {_sender, message} ->
        IO.puts "Received message: #{message}"
        receive_messages()
    end
  end

  def wait_for_process(pid) do
    Process.monitor(pid)
    receive do
      {:DOWN, _ref, :process, ^pid, _reason} -> :ok
    end
  end
end

receiver = Messages.receiver()
Messages.sender(receiver, "data.txt")
Messages.wait_for_process(receiver)
