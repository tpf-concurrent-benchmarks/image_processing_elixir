defmodule DistributedPipelineTest do
  use ExUnit.Case
  doctest DistributedPipeline

  test "greets the world" do
    assert DistributedPipeline.hello() == :world
  end
end
