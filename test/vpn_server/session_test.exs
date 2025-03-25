defmodule PhoenixVpn.SessionTest do
  use ExUnit.Case
  alias PhoenixVpn.Session

  setup do
    # Create a mock socket for testing
    {:ok, socket} = :gen_tcp.listen(0, [:binary, packet: :raw, active: false])

    on_exit(fn ->
      :gen_tcp.close(socket)
    end)

    {:ok, %{socket: socket}}
  end

  describe "start_link/3" do
    test "creates a new session with correct initial state", %{socket: socket} do
      username = "test_user"
      ip_address = "10.0.0.2"

      assert {:ok, pid} = Session.start_link(socket, username, ip_address)
      assert Process.alive?(pid)

      # Get the session state
      state = :sys.get_state(pid)
      assert state.username == username
      assert state.socket == socket
      assert state.ip_address == ip_address
      assert is_integer(state.call_id)
      assert state.sequence_number == 0

      # Clean up
      Process.exit(pid, :normal)
    end
  end

  describe "handle_info/2" do
    test "handles TCP data", %{socket: socket} do
      username = "test_user"
      ip_address = "10.0.0.2"
      {:ok, pid} = Session.start_link(socket, username, ip_address)

      # Create a test PPTP packet
      packet = <<
        # version
        1,
        # reserved
        0,
        # message_type (Start-Control-Connection-Request)
        1,
        0,
        # length
        12,
        0,
        # call_id
        1,
        0,
        # sequence_number
        1,
        0,
        0,
        0,
        # acknowledgment_number
        0,
        0,
        0,
        0,
        # payload
        "test"::binary
      >>

      # Send the packet to the session
      send(pid, {:tcp, socket, packet})

      # Give the process time to handle the message
      Process.sleep(100)

      # Verify the state was updated
      state = :sys.get_state(pid)
      assert state.sequence_number > 0

      # Clean up
      Process.exit(pid, :normal)
    end

    test "handles TCP closed", %{socket: socket} do
      username = "test_user"
      ip_address = "10.0.0.2"
      {:ok, pid} = Session.start_link(socket, username, ip_address)

      # Send close message
      send(pid, {:tcp_closed, socket})

      # Give the process time to handle the message
      Process.sleep(100)

      # Verify the process terminated
      refute Process.alive?(pid)
    end

    test "handles TCP error", %{socket: socket} do
      username = "test_user"
      ip_address = "10.0.0.2"
      {:ok, pid} = Session.start_link(socket, username, ip_address)

      # Send error message
      send(pid, {:tcp_error, socket, :connection_reset})

      # Give the process time to handle the message
      Process.sleep(100)

      # Verify the process terminated
      refute Process.alive?(pid)
    end
  end
end
