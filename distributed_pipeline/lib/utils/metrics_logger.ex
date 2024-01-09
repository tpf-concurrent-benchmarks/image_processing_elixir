defmodule MetricsLogger do
  def connect(host, port, prefix) do
    {:ok, socket} = :gen_udp.open(0, active: false)
    {:ok, {socket, host, port, prefix}}
  end

  def increment( {socket, host, port, prefix}, metric, value \\ 1) do
    :gen_udp.send(socket, host, port, "#{prefix}.#{metric}:#{value}|c")
  end

  def gauge( {socket, host, port, prefix}, metric, value) do
    :gen_udp.send(socket, host, port, "#{prefix}.#{metric}:#{value}|g")
  end

  def timing( {socket, host, port, prefix}, metric, value) do
    :gen_udp.send(socket, host, port, "#{prefix}.#{metric}:#{value}|ms")
  end

  def close( {socket, _host, _port, _prefix} ) do
    :gen_udp.close(socket)
  end
end

defmodule CustomMetricsLogger do

  def connect(name, replica) do
    replica_n = String.to_integer(replica) - 1
    prefix = "#{name}_#{replica_n}"
    connect(prefix)
  end

  def connect(prefix) do
    host = 'graphite'
    port = 8125
    IO.puts("Logger connecting to #{host}:#{port} with prefix #{prefix}")
    MetricsLogger.connect(host, port, prefix)
  end

end
