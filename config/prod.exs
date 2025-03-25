import Config

config :logger,
  level: :info,
  format: "$time $metadata[$level] $message\n"

config :phoenix_vpn,
  port: 1723,
  # Add your users here in format: {"username", "password"}
  users: [
    {"admin", "admin123"}
  ]
