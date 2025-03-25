defmodule VpnServer.Server do
  use GenServer
  require Logger

  # Standard PPTP port
  @default_port 1723
  # Standard VPN IP configuration
  @vpn_network "10.8.0"
  @vpn_server_ip "#{@vpn_network}.1"
  @vpn_pool_start "#{@vpn_network}.2"
  @vpn_pool_end "#{@vpn_network}.254"

  def start_link(opts \\ []) do
    port = Keyword.get(opts, :port, @default_port)

    Logger.info("VPN Network: #{@vpn_network}.0/24")
    Logger.info("VPN Server IP: #{@vpn_server_ip}")
    Logger.info("Client IP Range: #{@vpn_pool_start} - #{@vpn_pool_end}")

    GenServer.start_link(
      __MODULE__,
      %{
        port: port,
        config: nil,
        listen_socket: nil,
        acceptor_pid: nil,
        used_ips: MapSet.new()
      },
      name: __MODULE__
    )
  end

  def init(state) do
    {:ok, listen_socket} =
      :gen_tcp.listen(state.port, [
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

  def handle_call(:get_available_ip, _from, state) do
    case find_available_ip(state.used_ips) do
      {:ok, ip} ->
        new_used_ips = MapSet.put(state.used_ips, ip)
        {:reply, {:ok, ip}, %{state | used_ips: new_used_ips}}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:release_ip, ip}, _from, state) do
    new_used_ips = MapSet.delete(state.used_ips, ip)
    {:reply, :ok, %{state | used_ips: new_used_ips}}
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
    case GenServer.call(__MODULE__, :get_available_ip) do
      {:ok, ip} -> ip
      {:error, _} -> raise "No available IP addresses"
    end
  end

  defp find_available_ip(used_ips) do
    start_ip_int = ip_to_integer(@vpn_pool_start)
    end_ip_int = ip_to_integer(@vpn_pool_end)

    available_ip =
      Enum.find(start_ip_int..end_ip_int, fn ip_int ->
        ip = integer_to_ip(ip_int)
        not MapSet.member?(used_ips, ip)
      end)

    case available_ip do
      nil -> {:error, :no_available_ips}
      ip_int -> {:ok, integer_to_ip(ip_int)}
    end
  end

  defp ip_to_integer(ip) do
    ip
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> Enum.reduce(0, fn octet, acc -> acc * 256 + octet end)
  end

  defp integer_to_ip(int) do
    <<a::8, b::8, c::8, d::8>> = <<int::32>>
    "#{a}.#{b}.#{c}.#{d}"
  end

  defp create_success_response(packet) do
    # Create a PPTP Control-Connection-Reply packet
    response = <<
      # version
      1,
      # reserved
      0,
      # message_type (Control-Connection-Reply)
      2,
      0,
      # length (little-endian)
      12,
      0,
      # call_id (little-endian)
      packet.call_id::little-16,
      # sequence_number (little-endian)
      packet.sequence_number::little-32,
      # acknowledgment_number (little-endian)
      packet.sequence_number::little-32,
      # payload
      "Authentication successful"::binary
    >>

    {:ok, response}
  end

  defp create_error_response(packet, reason) do
    # Create a PPTP Control-Connection-Reply packet with error
    response = <<
      # version
      1,
      # reserved
      0,
      # message_type (Control-Connection-Reply)
      2,
      0,
      # length (little-endian)
      12,
      0,
      # call_id (little-endian)
      packet.call_id::little-16,
      # sequence_number (little-endian)
      packet.sequence_number::little-32,
      # acknowledgment_number (little-endian)
      packet.sequence_number::little-32,
      # payload
      "Authentication failed: #{inspect(reason)}"::binary
    >>

    {:ok, response}
  end
end
