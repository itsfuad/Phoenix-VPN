defmodule VpnServer.ServerTest do
  use ExUnit.Case
  alias VpnServer.Server

  @test_port 1723  # Use the default PPTP port

  setup do
    # Stop any existing server
    if Process.whereis(Server) do
      Process.exit(Process.whereis(Server), :normal)
      Process.sleep(100)  # Give it time to exit
    end

    # Start the server with a test port
    case Server.start_link(port: @test_port) do
      {:ok, pid} ->
        Process.sleep(100)  # Give it time to initialize
        on_exit(fn ->
          if Process.alive?(pid) do
            Process.exit(pid, :normal)
            Process.sleep(100)
          end
        end)
        {:ok, %{pid: pid}}
      {:error, {:already_started, pid}} ->
        Process.sleep(100)  # Give it time to initialize
        on_exit(fn ->
          if Process.alive?(pid) do
            Process.exit(pid, :normal)
            Process.sleep(100)
          end
        end)
        {:ok, %{pid: pid}}
      error ->
        flunk("Failed to start server: #{inspect(error)}")
    end
  end

  describe "init/1" do
    test "initializes server with correct port", %{pid: pid} do
      # Wait for server to be ready
      Process.sleep(100)

      # Try to get state
      state = GenServer.call(pid, :get_state)
      assert Process.alive?(pid)
      assert state.port == @test_port
    end
  end

  describe "handle_info/2" do
    test "accepts new connections", %{pid: pid} do
      # Give the server time to initialize
      Process.sleep(100)

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
      # Give the server time to initialize
      Process.sleep(100)

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
        12, 0,# length (little-endian)
        1, 0, # call_id (little-endian)
        1, 0, 0, 0, # sequence_number (little-endian)
        0, 0, 0, 0, # acknowledgment_number (little-endian)
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
      # Give the server time to initialize
      Process.sleep(100)

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
