defmodule VpnServer.Config do
  @moduledoc """
  Configuration module for VPN server settings and user credentials.
  """

  defstruct [
    :users,
    :ip_pool_start,
    :ip_pool_end,
    :dns_servers
  ]

  def new do
    %__MODULE__{
      users: %{
        "admin" => "admin123"  # Replace with secure credentials in production
      },
      ip_pool_start: "10.0.0.2",
      ip_pool_end: "10.0.0.254",
      dns_servers: ["8.8.8.8", "8.8.4.4"]
    }
  end

  def authenticate_user(username, password) do
    case get_user_password(username) do
      {:ok, stored_password} when stored_password == password ->
        {:ok, username}
      {:ok, _} ->
        {:error, :invalid_password}
      {:error, _} ->
        {:error, :user_not_found}
    end
  end

  defp get_user_password(username) do
    case Application.get_env(:vpn_server, :users) do
      nil ->
        {:error, :user_not_found}
      users ->
        case Map.get(users, username) do
          nil -> {:error, :user_not_found}
          password -> {:ok, password}
        end
    end
  end
end
