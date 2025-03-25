#!/bin/bash
set -e

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Configure iptables for PPTP
iptables -A INPUT -p tcp --dport 1723 -j ACCEPT
iptables -A INPUT -p gre -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

# Start VPN server
exec /vpn_server/bin/vpn_server start 