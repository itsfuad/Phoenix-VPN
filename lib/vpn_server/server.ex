defmodule VpnServer.Server do
  use GenServer
  require Logger

  @default_port 1723  # Standard PPTP port

  def start_link(opts \\ []) do
    port = Keyword.get(opts, :port, @default_port)
    GenServer.start_link(__MODULE__, %{
      port: port,
      config: nil,
      listen_socket: nil,
      acceptor_pid: nil
    }, name: __MODULE__)
  end

  def init(state) do
    {:ok, listen_socket} = :gen_tcp.listen(state.port, [
      :binary,
      packet: :raw,
      active: false,
      reuseaddr: true
    ])

    config = VpnServer.Config.new()
    Logger.info("VPN Server listening on port #{state.port}")

    # Start a separate process for accepting connections
    acceptor_pid = spawn_link(fn -> accept_connections(listen_socket, config) end)

    {:ok, %{state | listen_socket: listen_socket, config: config, acceptor_pid: acceptor_pid}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  defp accept_connections(listen_socket, config) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, socket} ->
        Logger.info("New VPN connection accepted")
        spawn_link(fn -> handle_client(socket, config) end)
        accept_connections(listen_socket, config)

      {:error, reason} ->
        Logger.error("Failed to accept connection: #{inspect(reason)}")
        accept_connections(listen_socket, config)
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
    # Create a PPTP Control-Connection-Reply packet
    response = <<
      1,    # version
      0,    # reserved
      2, 0, # message_type (Control-Connection-Reply)
      12, 0,# length (little-endian)
      packet.call_id::little-16, # call_id (little-endian)
      packet.sequence_number::little-32, # sequence_number (little-endian)
      packet.sequence_number::little-32, # acknowledgment_number (little-endian)
      "Authentication successful"::binary # payload
    >>
    {:ok, response}
  end

  defp create_error_response(packet, reason) do
    # Create a PPTP Control-Connection-Reply packet with error
    response = <<
      1,    # version
      0,    # reserved
      2, 0, # message_type (Control-Connection-Reply)
      12, 0,# length (little-endian)
      packet.call_id::little-16, # call_id (little-endian)
      packet.sequence_number::little-32, # sequence_number (little-endian)
      packet.sequence_number::little-32, # acknowledgment_number (little-endian)
      "Authentication failed: #{inspect(reason)}"::binary # payload
    >>
    {:ok, response}
  end
end
