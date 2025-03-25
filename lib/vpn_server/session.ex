defmodule PhoenixVpn.Session do
  use GenServer
  require Logger

  defstruct [
    :username,
    :socket,
    :ip_address,
    :call_id,
    :sequence_number
  ]

  def start_link(socket, username, ip_address) do
    GenServer.start_link(__MODULE__, {socket, username, ip_address})
  end

  def init({socket, username, ip_address}) do
    state = %__MODULE__{
      username: username,
      socket: socket,
      ip_address: ip_address,
      call_id: :rand.uniform(65535),
      sequence_number: 0
    }

    Logger.info("New VPN session started for user #{username} with IP #{ip_address}")
    {:ok, state}
  end

  def handle_info({:tcp, _socket, data}, state) do
    case PhoenixVpn.PPTPProtocol.parse_packet(data) do
      {:ok, packet} ->
        handle_packet(packet, state)

      {:error, reason} ->
        Logger.error("Failed to parse PPTP packet: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Logger.info("VPN session closed for user #{state.username}")
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    Logger.error("TCP error for user #{state.username}: #{inspect(reason)}")
    {:stop, :normal, state}
  end

  defp handle_packet(packet, state) do
    case packet.message_type do
      # Start-Control-Connection-Request
      1 ->
        handle_control_connection_request(packet, state)

      # Echo-Request
      3 ->
        handle_echo_request(packet, state)

      # Outgoing-Call-Request
      5 ->
        handle_outgoing_call_request(packet, state)

      _ ->
        Logger.warning("Unhandled PPTP message type: #{packet.message_type}")
        {:noreply, state}
    end
  end

  defp handle_control_connection_request(packet, state) do
    response =
      PhoenixVpn.PPTPProtocol.create_control_connection_reply(
        packet.call_id,
        packet.sequence_number
      )

    :gen_tcp.send(state.socket, PhoenixVpn.PPTPProtocol.build_packet(response))
    {:noreply, %{state | sequence_number: state.sequence_number + 1}}
  end

  defp handle_echo_request(packet, state) do
    response =
      PhoenixVpn.PPTPProtocol.create_echo_reply(
        packet.call_id,
        packet.sequence_number
      )

    :gen_tcp.send(state.socket, PhoenixVpn.PPTPProtocol.build_packet(response))
    {:noreply, %{state | sequence_number: state.sequence_number + 1}}
  end

  defp handle_outgoing_call_request(packet, state) do
    # Here we would handle the actual VPN connection setup
    # For now, just acknowledge the request
    response = %PhoenixVpn.PPTPProtocol{
      version: 1,
      # Outgoing-Call-Reply
      message_type: 6,
      length: 12,
      call_id: packet.call_id,
      sequence_number: state.sequence_number,
      acknowledgment_number: packet.sequence_number,
      payload: <<>>
    }

    :gen_tcp.send(state.socket, PhoenixVpn.PPTPProtocol.build_packet(response))
    {:noreply, %{state | sequence_number: state.sequence_number + 1}}
  end
end
