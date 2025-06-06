defmodule PhoenixVpn.Application do
  use Application

  def start(_type, _args) do
    children = [
      PhoenixVpn.Server
    ]

    opts = [strategy: :one_for_one, name: PhoenixVpn.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
