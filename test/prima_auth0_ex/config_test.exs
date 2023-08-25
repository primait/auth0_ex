defmodule ConfigTest do
  use ExUnit.Case, async: true

  alias PrimaAuth0Ex.Config

  describe "can read default client config" do
    test "by getting whole config" do
      config = Config.default_client()

      assert config[:auth0_base_url] == "default"
      assert config[:client_id] == "default"
      assert config[:client_secret] == "default"
      assert config[:cache_namespace] == "default"
      assert config[:token_check_interval] == :timer.seconds(1)
      assert config[:signature_check_interval] == :timer.seconds(1)
    end

    test "by getting specific props" do
      assert Config.default_client(:auth0_base_url) == "default"
      assert Config.default_client(:client_id) == "default"
      assert Config.default_client(:client_secret) == "default"
      assert Config.default_client(:cache_namespace) == "default"
      assert Config.default_client(:token_check_interval) == :timer.seconds(1)
      assert Config.default_client(:signature_check_interval) == :timer.seconds(1)
    end

    test "and set defaults if prop is missing and one is provided" do
      assert Config.default_client(:non_existing_property) == nil
      assert Config.default_client(:non_existing_property, 1) == 1
    end

    test "bang version" do
      assert_raise KeyError, fn -> Config.default_client!(:non_existing_property) end
      assert Config.default_client!(:client_id) == "default"
    end
  end

  test "can get all clients" do
    assert Keyword.keys(Config.clients()) == [:default_client, :test_client]
  end

  describe "can read specific client config" do
    test "by getting whole config" do
      config = Config.clients(:test_client)

      assert config[:auth0_base_url] == "test"
      assert config[:client_id] == "test"
      assert config[:client_secret] == "test"
      assert config[:cache_namespace] == "test"
      assert config[:token_check_interval] == :timer.seconds(1)
      assert config[:signature_check_interval] == :timer.seconds(1)
    end

    test "by getting specific props" do
      assert Config.clients(:test_client, :auth0_base_url, "default") == "test"
      assert Config.clients(:test_client, :client_id, "default") == "test"
      assert Config.clients(:test_client, :client_secret, "default") == "test"
      assert Config.clients(:test_client, :cache_namespace, "default") == "test"
      assert Config.clients(:test_client, :token_check_interval, 0) == :timer.seconds(1)
      assert Config.clients(:test_client, :signature_check_interval, 0) == :timer.seconds(1)
    end

    test "and set defaults if prop is missing and one is provided" do
      assert Config.clients(:test_client, :non_existing_property, 1) == 1
    end

    test "bang version" do
      assert_raise KeyError, fn -> Config.clients!(:test_client, :non_existing_property) end
      assert Config.clients!(:test_client, :client_id) == "test"
    end
  end

  test "can read redis config" do
    assert Config.redis(:enabled) == true
    assert Config.redis(:encryption_key) == "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA="
    assert Config.redis(:connection_uri) == "redis://redis:6379"
    assert Config.redis(:ssl_enabled) == false
    assert Config.redis(:ssl_allow_wildcard_certificates) == false
  end

  describe "can read server config" do
    test "by getting whole config" do
      config = Config.server()

      assert config[:auth0_base_url] == "server"
      assert config[:ignore_signature] == false
      assert config[:audience] == "server"
      assert config[:issuer] == "server"
      assert config[:first_jwks_fetch_sync] == true
    end

    test "by getting specific props" do
      assert Config.server(:auth0_base_url) == "server"
      assert Config.server(:ignore_signature) == false
      assert Config.server(:audience) == "server"
      assert Config.server(:issuer) == "server"
      assert Config.server(:first_jwks_fetch_sync) == true
    end

    test "by getting specific props with a bang" do
      assert Config.server!(:auth0_base_url) == "server"
      assert_raise KeyError, fn -> Config.server!(:non_existing_property) end
    end
  end

  test "can read configured dependencies" do
    Config.authorization_service(nil)
    Config.jwks_kids_fetcher(nil)
    Config.refresh_strategy(nil)
    Config.telemetry_reporter()
    Config.token_cache(nil)
    Config.token_service(nil)
  end
end
