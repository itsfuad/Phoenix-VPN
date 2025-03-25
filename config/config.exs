import Config

config :phoenix_vpn,
  users: %{
    # Replace with secure credentials in production
    "admin" => "admin123"
  },
  ip_pool_start: "10.0.0.2",
  ip_pool_end: "10.0.0.254",
  dns_servers: ["8.8.8.8", "8.8.4.4"]
