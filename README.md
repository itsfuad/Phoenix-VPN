# Phoenix VPN

## About

Built with Elixir, this project provides a robust PPTP VPN server designed for reliability and scalability. Leveraging Elixir's concurrent capabilities, it efficiently manages multiple VPN connections while ensuring proper error handling and maintainability. The implementation is structured for easy enhancements, making it a solid foundation for further improvements in authentication, encryption, and network routing.

## System Requirements

- Elixir 1.14 or later
- Erlang/OTP 24 or later
- Root/Administrator privileges
- Open port 1723 (PPTP)
- IP forwarding enabled
- Windows/Android client with PPTP VPN support

## Project Structure

- `lib/phoenix_vpn/pptp_protocol.ex` - PPTP protocol implementation
- `lib/phoenix_vpn/server.ex` - TCP server for handling VPN connections
- `lib/phoenix_vpn/session.ex` - Session management for VPN clients
- `lib/phoenix_vpn/config.ex` - Configuration and user authentication
- `lib/phoenix_vpn/application.ex` - OTP application entry point

## Development Setup

1. Install dependencies:
```bash
mix deps.get
```

2. Compile the project:
```bash
mix compile
```

3. Start the VPN server in development:
```bash
mix run --no-halt
```

## Deployment

### Pre-deployment Setup

1. Enable IP Forwarding (Linux):
```bash
# Add to /etc/sysctl.conf
net.ipv4.ip_forward=1

# Apply changes
sudo sysctl -p
```

2. Configure Firewall:
```bash
# Allow PPTP traffic
sudo iptables -A INPUT -p tcp --dport 1723 -j ACCEPT
sudo iptables -A INPUT -p gre -j ACCEPT

# Enable NAT
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
```

3. Configure User Authentication:
Edit `config/prod.exs`:
```elixir
config :phoenix_vpn,
  users: [
    {"username", "password"}
  ]
```

### Deployment Steps

1. Build Release:
```bash
MIX_ENV=prod mix release
```

2. Run Server:
```bash
sudo _build/prod/rel/phoenix_vpn/bin/phoenix_vpn start
```

## Client Setup

### Windows Client
1. Open Windows Settings
2. Go to Network & Internet > VPN
3. Click "Add a VPN connection"
4. Fill in the following details:
   - VPN provider: Windows (built-in)
   - Connection name: Elixir VPN
   - Server name or address: Your server's IP address
   - VPN type: PPTP
   - Type of sign-in info: Username and password
   - Username: As configured in prod.exs
   - Password: As configured in prod.exs
5. Click Save

### Android Client
1. Settings -> Network & Internet -> VPN
2. Add VPN Configuration
3. Set:
   - Type: PPTP
   - Server Address: Your server's public IP
   - Username/Password: As configured in prod.exs

## Testing

Run the test suite with:

```bash
mix test
```

Note: The test output may show some error messages like "Failed to process PPTP packet" or "TCP error". These are expected and part of the test cases that verify error handling paths.

## Troubleshooting

1. Check server logs:
```bash
_build/prod/rel/phoenix_vpn/bin/phoenix_vpn remote
```

2. Common Issues:
   - Port 1723 not open
   - IP forwarding not enabled
   - Firewall blocking PPTP/GRE
   - Missing root privileges

## Security Considerations

This is a basic implementation and should be enhanced with:
- Proper authentication
- Encryption
- IP address assignment
- Routing configuration
- Firewall rules

## License

This project is licensed under the Mozilla Public License 2.0. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your changes. Make sure to follow the coding style and include tests for any new features or bug fixes.
- For major changes, please open an issue first to discuss what you would like to change.
- Ensure your code passes all tests and adheres to the project's coding standards.

## Acknowledgments

- Thanks to the Elixir community for their support and resources.
- Inspired by the simplicity and power of Elixir for network programming.
- Special thanks to the authors of the Elixir and Erlang documentation for their invaluable insights.