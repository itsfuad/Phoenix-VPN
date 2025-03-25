import Config

config :logger,
  level: :info,
  format: "$time $metadata[$level] $message\n"

config :vpn_server,
  port: 1723,
  # Add your users here in format: {"username", "password"}
  users: [
    {"admin", "admin123"}
  ]
