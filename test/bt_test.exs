defmodule BtTest do
  use ExUnit.Case
  doctest Bt

  test "greets the world" do
    assert Bt.hello() == :world
  end
end
