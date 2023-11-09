defmodule Integration.TokenProvider.MultiClientsTest do
  use ExUnit.Case, async: false

  import PrimaAuth0Ex.TestSupport.TimeUtils
  alias PrimaAuth0Ex.Config
  alias PrimaAuth0Ex.TokenProvider.TokenInfo
  alias PrimaAuth0Ex.TokenCache.EncryptedRedisTokenCache

  @test_audience "redis-integration-test-audience"
  @test_client :test_client
  @clients [@test_client, :default_client]

  setup do
    start_supervised(EncryptedRedisTokenCache)
    for client <- @clients do
      Redix.command!(PrimaAuth0Ex.Redix, ["DEL", token_key(client, @test_audience)])
    end

    :ok
  end

  test "persists and retrieves tokens for multiple clients" do
    token = sample_token()
    :ok = EncryptedRedisTokenCache.set_token_for(@test_client, @test_audience, token)

    assert {:ok, token} == EncryptedRedisTokenCache.get_token_for(@test_client, @test_audience)

    # Other client should not be able to retrieve any token yet
    assert {:ok, nil} ==
             EncryptedRedisTokenCache.get_token_for(@test_audience)

    :ok = EncryptedRedisTokenCache.set_token_for(@test_audience, token)

    # Only when explicitly set, the token can be gotten
    assert {:ok, token} ==
             EncryptedRedisTokenCache.get_token_for(@test_audience)
  end

  test "retrieves tokens set by a previous version of prima_auth0_ex, hence without kid (but not for other clients)" do
    issued_at = one_hour_ago()
    expires_at = in_one_hour()
    token_without_kid = %{jwt: "my-token", issued_at: issued_at, expires_at: expires_at}

    :ok = EncryptedRedisTokenCache.set_token_for(@test_client, @test_audience, token_without_kid)

    assert {:ok, %TokenInfo{jwt: "my-token", issued_at: ^issued_at, expires_at: ^expires_at, kid: nil}} =
             EncryptedRedisTokenCache.get_token_for(@test_client, @test_audience)

    # Other client should not be able to retrieve this token
    assert {:ok, nil} = EncryptedRedisTokenCache.get_token_for(@test_audience)
  end

  test "token encryption works with multiple clients" do
    :ok = EncryptedRedisTokenCache.set_token_for(@test_client, @test_audience, sample_token())

    persisted_token = Redix.command!(PrimaAuth0Ex.Redix, ["GET", token_key(@test_client, @test_audience)])

    assert is_binary(persisted_token)
    assert {:error, _} = Jason.decode(persisted_token)
  end

  test "tokens are deleted from cache when they expire, but other clients are not affected" do
    short_expiration_token = %TokenInfo{sample_token() | expires_at: in_one_second()}
    normal_expiration_token = sample_token()

    :ok = EncryptedRedisTokenCache.set_token_for(@test_client, @test_audience, short_expiration_token)

    :ok =
      EncryptedRedisTokenCache.set_token_for(
        @test_audience,
        normal_expiration_token
      )

    assert {:ok, ^short_expiration_token} = EncryptedRedisTokenCache.get_token_for(@test_client, @test_audience)

    assert {:ok, ^normal_expiration_token} = EncryptedRedisTokenCache.get_token_for(@test_audience)

    :timer.sleep(1100)

    assert {:ok, nil} = EncryptedRedisTokenCache.get_token_for(@test_client, @test_audience)

    assert {:ok, ^normal_expiration_token} = EncryptedRedisTokenCache.get_token_for(@test_audience)
  end

  test "tokens are deleted from cache when they expire, even for multiple clients" do
    short_expiration_token = %TokenInfo{sample_token() | expires_at: in_one_second()}

    :ok = EncryptedRedisTokenCache.set_token_for(@test_client, @test_audience, short_expiration_token)

    :ok =
      EncryptedRedisTokenCache.set_token_for(
        @test_audience,
        short_expiration_token
      )

    assert {:ok, ^short_expiration_token} = EncryptedRedisTokenCache.get_token_for(@test_client, @test_audience)

    assert {:ok, ^short_expiration_token} = EncryptedRedisTokenCache.get_token_for(@test_audience)

    :timer.sleep(1100)

    assert {:ok, nil} = EncryptedRedisTokenCache.get_token_for(@test_client, @test_audience)
    assert {:ok, nil} = EncryptedRedisTokenCache.get_token_for(@test_audience)
  end

  defp sample_token do
    %TokenInfo{
      jwt: "my-token",
      issued_at: one_hour_ago(),
      expires_at: in_one_hour(),
      kid: "my-kid"
    }
  end

  defp token_key(client, audience), do: "prima_auth0_ex_tokens:#{namespace(client)}:#{audience}"

  defp namespace(client),
    do: Config.clients!(client, :cache_namespace)

  defp in_one_second, do: Timex.now() |> Timex.shift(seconds: 1) |> Timex.to_unix()
end
