# Elixir VPN Server

A simple PPTP VPN server implementation in Elixir.

## Requirements

- Elixir 1.14 or later
- Erlang/OTP 24 or later
- Windows client with PPTP VPN support

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
   - Username: (your username)
   - Password: (your password)
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

