# Phoenix VPN

## About

Built with Elixir, this project provides a robust PPTP VPN server designed for reliability and scalability. Leveraging Elixir’s concurrent capabilities, it efficiently manages multiple VPN connections while ensuring proper error handling and maintainability. The implementation is structured for easy enhancements, making it a solid foundation for further improvements in authentication, encryption, and network routing.

## Requirements

- Elixir 1.14 or later
- Erlang/OTP 24 or later
- Windows client with PPTP VPN support

## Project Structure

- `lib/phoenix_vpn/pptp_protocol.ex` - PPTP protocol implementation
- `lib/phoenix_vpn/server.ex` - TCP server for handling VPN connections
- `lib/phoenix_vpn/session.ex` - Session management for VPN clients
- `lib/phoenix_vpn/config.ex` - Configuration and user authentication
- `lib/phoenix_vpn/application.ex` - OTP application entry point

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

This project is licensed under the Mozilla Public License 2.0. See the [LICENSE](LICENSE) file for details.

## Acknowledgments
- Thanks to the Elixir community for their support and resources.
- Inspired by the simplicity and power of Elixir for network programming.
- Special thanks to the authors of the Elixir and Erlang documentation for their invaluable insights.

## Contributing
Contributions are welcome! Please fork the repository and submit a pull request with your changes. Make sure to follow the coding style and include tests for any new features or bug fixes.
- For major changes, please open an issue first to discuss what you would like to change.
- Ensure your code passes all tests and adheres to the project's coding standards.