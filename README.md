# Phoenix VPN

A robust PPTP VPN server implementation in Elixir.

## Requirements

- Elixir 1.14 or later
- Erlang/OTP 24 or later
- Windows client with PPTP VPN support

## Project Structure

- `lib/vpn_server/pptp_protocol.ex` - PPTP protocol implementation
- `lib/vpn_server/server.ex` - TCP server for handling VPN connections
- `lib/vpn_server/session.ex` - Session management for VPN clients
- `lib/vpn_server/config.ex` - Configuration and user authentication
- `lib/vpn_server/application.ex` - OTP application entry point

## Building and Running

1. Install dependencies:
```bash
mix deps.get
```

2. Compile the project:
```bash
mix compile
```

3. Start the VPN server:
```bash
mix run --no-halt
```

## Testing

Run the test suite with:

```bash
mix test
```

Note: The test output may show some error messages like "Failed to process PPTP packet" or "TCP error". These are expected and part of the test cases that verify error handling paths.

## Default Credentials

The default user account is:
- Username: `admin`
- Password: `admin123`

You can modify these in `config/config.exs`.

## Windows Client Configuration

1. Open Windows Settings
2. Go to Network & Internet > VPN
3. Click "Add a VPN connection"
4. Fill in the following details:
   - VPN provider: Windows (built-in)
   - Connection name: Elixir VPN
   - Server name or address: Your server's IP address
   - VPN type: PPTP
   - Type of sign-in info: Username and password
   - Username: `admin` (or your custom username)
   - Password: `admin123` (or your custom password)
5. Click Save

## Security Considerations

This is a basic implementation and should be enhanced with:
- Proper authentication
- Encryption
- IP address assignment
- Routing configuration
- Firewall rules

## License

MIT

