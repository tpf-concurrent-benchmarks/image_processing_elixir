defmodule MetricsLogger do

  use Statix, runtime_config: true

  def init() do
    host = "graphite"
    port = 8125
    prefix = elem(:inet.gethostname(), 1)
    IO.puts("prefix: #{inspect prefix}")
    config = [prefix: prefix, host: host, port: port]
    :ok = connect(config)
    {:ok, config}
  end

end
