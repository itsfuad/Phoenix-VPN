# VPN Server Deployment Guide

## System Requirements

1. Elixir 1.14 or later
2. Root/Administrator privileges
3. Open port 1723 (PPTP)
4. IP forwarding enabled

## Pre-deployment Setup

### 1. Enable IP Forwarding (Linux)
```bash
# Add to /etc/sysctl.conf
net.ipv4.ip_forward=1

# Apply changes
sudo sysctl -p
```

### 2. Configure Firewall
```bash
# Allow PPTP traffic
sudo iptables -A INPUT -p tcp --dport 1723 -j ACCEPT
sudo iptables -A INPUT -p gre -j ACCEPT

# Enable NAT
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
```

### 3. Configure User Authentication
Edit `config/prod.exs`:
```elixir
config :vpn_server,
  users: [
    {"username", "password"}
  ]
```

## Deployment Steps

1. Build Release:
```bash
MIX_ENV=prod mix release
```

2. Run Server:
```bash
sudo _build/prod/rel/vpn_server/bin/vpn_server start
```

## Client Setup

### Windows
1. Open Network Settings
2. Add VPN Connection
3. Set:
   - VPN Type: PPTP
   - Server Address: Your server's public IP
   - Username/Password: As configured

### Android
1. Settings -> Network & Internet -> VPN
2. Add VPN Configuration
3. Set:
   - Type: PPTP
   - Server Address: Your server's public IP
   - Username/Password: As configured

## Troubleshooting

1. Check server logs:
```bash
_build/prod/rel/vpn_server/bin/vpn_server remote
```

2. Common Issues:
   - Port 1723 not open
   - IP forwarding not enabled
   - Firewall blocking PPTP/GRE
   - Missing root privileges 