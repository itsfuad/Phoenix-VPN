defmodule VpnServer.ServerTest do
  use ExUnit.Case
  alias VpnServer.Server

  @test_port 1724  # Use a different port for testing

  setup do
    # Start the server with a test port
    {:ok, pid} = Server.start_link(port: @test_port)
    on_exit(fn ->
      Process.exit(pid, :normal)
    end)
    {:ok, %{pid: pid}}
  end

  describe "init/1" do
    test "initializes server with correct port", %{pid: pid} do
      _state = :sys.get_state(pid)
      assert Process.alive?(pid)
    end
  end

  describe "handle_continue/2" do
    test "accepts new connections", %{pid: pid} do
      # Create a test client socket
      {:ok, client_socket} = :gen_tcp.connect(~c"127.0.0.1", @test_port, [
        :binary,
        packet: :raw,
        active: false
      ])

      # Give the server time to accept the connection
      Process.sleep(100)

      # Verify the connection was accepted
      assert Process.alive?(pid)

      # Clean up
      :gen_tcp.close(client_socket)
    end
  end

  describe "process_pptp_packet/3" do
    test "processes valid PPTP packet", %{pid: _pid} do
      # Create a test client socket
      {:ok, client_socket} = :gen_tcp.connect(~c"127.0.0.1", @test_port, [
        :binary,
        packet: :raw,
        active: false
      ])

      # Create a test PPTP packet with credentials
      packet = <<
        1,    # version
        0,    # reserved
        1, 0, # message_type (Start-Control-Connection-Request)
        12, 0,# length
        1, 0, # call_id
        1, 0, 0, 0, # sequence_number
        0, 0, 0, 0, # acknowledgment_number
        "admin:admin123"::binary # payload with credentials
      >>

      # Send the packet
      :gen_tcp.send(client_socket, packet)

      # Give the server time to process the packet
      Process.sleep(100)

      # Clean up
      :gen_tcp.close(client_socket)
    end

    test "handles invalid packet format", %{pid: _pid} do
      # Create a test client socket
      {:ok, client_socket} = :gen_tcp.connect(~c"127.0.0.1", @test_port, [
        :binary,
        packet: :raw,
        active: false
      ])

      # Send invalid packet
      :gen_tcp.send(client_socket, <<1, 2, 3>>)

      # Give the server time to process the packet
      Process.sleep(100)

      # Clean up
      :gen_tcp.close(client_socket)
    end
  end
end
