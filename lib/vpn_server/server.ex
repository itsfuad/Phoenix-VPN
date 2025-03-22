defmodule VpnServer.Server do
  use GenServer
  require Logger

  @port 1723  # Standard PPTP port

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_state) do
    {:ok, listen_socket} = :gen_tcp.listen(@port, [
      :binary,
      packet: :raw,
      active: false,
      reuseaddr: true
    ])

    config = VpnServer.Config.new()
    Logger.info("VPN Server listening on port #{@port}")
    {:ok, %{listen_socket: listen_socket, config: config}, {:continue, :accept}}
  end

  def handle_continue(:accept, state) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        Logger.info("New VPN connection accepted")
        spawn_link(fn -> handle_client(socket, state.config) end)
        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        Logger.error("Failed to accept connection: #{inspect(reason)}")
        {:noreply, state, {:continue, :accept}}
    end
  end

  defp handle_client(socket, config) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        case process_pptp_packet(data, socket, config) do
          {:ok, response} ->
            :gen_tcp.send(socket, response)
            handle_client(socket, config)
          {:error, reason} ->
            Logger.error("Failed to process PPTP packet: #{inspect(reason)}")
            :gen_tcp.close(socket)
        end

      {:error, :closed} ->
        Logger.info("Client disconnected")
        :gen_tcp.close(socket)

      {:error, reason} ->
        Logger.error("Error receiving data: #{inspect(reason)}")
        :gen_tcp.close(socket)
    end
  end

  defp process_pptp_packet(data, socket, config) do
    case VpnServer.PPTPProtocol.parse_packet(data) do
      {:ok, packet} ->
        case authenticate_connection(packet, config) do
          {:ok, username} ->
            ip_address = assign_ip_address()
            {:ok, _pid} = VpnServer.Session.start_link(socket, username, ip_address)
            create_success_response(packet)
          {:error, reason} ->
            create_error_response(packet, reason)
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp authenticate_connection(packet, _config) do
    # Extract username and password from packet payload
    # This is a simplified version - in production, you'd need proper PPTP authentication
    case extract_credentials(packet.payload) do
      {:ok, {username, password}} ->
        VpnServer.Config.authenticate_user(username, password)
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_credentials(payload) do
    # This is a simplified version - in production, you'd need proper PPTP authentication
    # For now, we'll just use a basic format: "username:password"
    case String.split(payload, ":") do
      [username, password] -> {:ok, {username, password}}
      _ -> {:error, :invalid_credentials_format}
    end
  end

  defp assign_ip_address do
    # In production, you'd want to implement proper IP address management
    # For now, just return a static IP
    "10.0.0.2"
  end

  defp create_success_response(packet) do
    response = %VpnServer.PPTPProtocol{
      version: 1,
      message_type: 2, # Control-Connection-Reply
      length: 12,
      call_id: packet.call_id,
      sequence_number: packet.sequence_number,
      acknowledgment_number: packet.sequence_number,
      payload: "Authentication successful"
    }
    {:ok, VpnServer.PPTPProtocol.build_packet(response)}
  end

  defp create_error_response(packet, reason) do
    response = %VpnServer.PPTPProtocol{
      version: 1,
      message_type: 2, # Control-Connection-Reply
      length: 12,
      call_id: packet.call_id,
      sequence_number: packet.sequence_number,
      acknowledgment_number: packet.sequence_number,
      payload: "Authentication failed: #{inspect(reason)}"
    }
    {:ok, VpnServer.PPTPProtocol.build_packet(response)}
  end
end
