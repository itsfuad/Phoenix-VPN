defmodule VpnServerTest do
  use ExUnit.Case
  doctest VpnServer

  test "greets the world" do
    assert VpnServer.hello() == :world
  end
end
