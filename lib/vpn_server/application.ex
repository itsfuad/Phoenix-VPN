defmodule VpnServer.Application do
  use Application

  def start(_type, _args) do
    children = [
      VpnServer.Server
    ]

    opts = [strategy: :one_for_one, name: VpnServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
