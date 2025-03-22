defmodule VpnServer.ConfigTest do
  use ExUnit.Case
  alias VpnServer.Config

  setup do
    # Set up test configuration
    Application.put_env(:vpn_server, :users, %{
      "test_user" => "test_password"
    })

    :ok
  end

  describe "authenticate_user/2" do
    test "authenticates valid user" do
      assert {:ok, "test_user"} = Config.authenticate_user("test_user", "test_password")
    end

    test "rejects invalid password" do
      assert {:error, :invalid_password} = Config.authenticate_user("test_user", "wrong_password")
    end

    test "rejects non-existent user" do
      assert {:error, :user_not_found} = Config.authenticate_user("nonexistent", "password")
    end
  end

  describe "new/0" do
    test "creates new config with default values" do
      config = Config.new()
      assert config.ip_pool_start == "10.0.0.2"
      assert config.ip_pool_end == "10.0.0.254"
      assert config.dns_servers == ["8.8.8.8", "8.8.4.4"]
      assert is_map(config.users)
    end
  end
end
