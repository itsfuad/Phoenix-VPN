defmodule VpnServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :vpn_server,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {VpnServer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    []
  end

  defp releases do
    [
      vpn_server: [
        include_executables_for: [:unix],
        applications: [
          vpn_server: :permanent
        ],
        steps: [:assemble, :tar]
      ]
    ]
  end
end
