defmodule Messages do
  def sender(receiver, messages) do
    spawn_link(fn -> send_messages(receiver, messages) end)
  end

  defp send_messages(receiver, messages) do
    Enum.each(messages, &send_message(receiver, &1))
    send(receiver, {self(), :stop})
  end

  defp send_message(receiver, message) do
    send(receiver, {self(), message})
    :timer.sleep(1000) # wait for 1 second
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
end

receiver = Messages.receiver()
Messages.sender(receiver, ["Hello", "World"])
