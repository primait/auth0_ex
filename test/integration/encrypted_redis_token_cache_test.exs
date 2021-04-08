defmodule Auth0Ex.TokenProvider.EncryptedRedisTokenCacheTest do
  use ExUnit.Case, async: true

  import Auth0Ex.TestSupport.TimeUtils
  alias Auth0Ex.TokenProvider.{EncryptedRedisTokenCache, TokenInfo}

  @test_audience "redis-integration-test-audience"

  setup do
    redis_connection_uri = Application.fetch_env!(:auth0_ex, :client)[:redis_connection_uri]
    Redix.start_link(redis_connection_uri, name: Auth0Ex.Redix)
    Redix.command!(Auth0Ex.Redix, ["DEL", token_key(@test_audience)])

    :ok
  end

  test "persists and retrieves tokens" do
    token = sample_token()
    :ok = EncryptedRedisTokenCache.set_token_for(@test_audience, token)

    assert {:ok, token} == EncryptedRedisTokenCache.get_token_for(@test_audience)
  end

  test "returns {:ok, nil} when token is not cached" do
    assert {:ok, nil} == EncryptedRedisTokenCache.get_token_for(@test_audience)
  end

  test "encrypts tokens" do
    :ok = EncryptedRedisTokenCache.set_token_for(@test_audience, sample_token())

    persisted_token = Redix.command!(Auth0Ex.Redix, ["GET", token_key(@test_audience)])

    assert is_binary(persisted_token)
    assert {:error, _} = Jason.decode(persisted_token)
  end

  @tag capture_log: true
  test "returns error when persisted tokens are invalid and could not be decrypted" do
    # this may happen e.g., if the secret key changes
    Redix.command!(Auth0Ex.Redix, ["SET", token_key(@test_audience), "malformed-encrypted-token"])

    assert {:error, _} = EncryptedRedisTokenCache.get_token_for(@test_audience)
  end

  test "tokens are deleted from cache when they expire" do
    token = %TokenInfo{sample_token() | expires_at: in_two_seconds()}
    :ok = EncryptedRedisTokenCache.set_token_for(@test_audience, token)

    assert {:ok, ^token} = EncryptedRedisTokenCache.get_token_for(@test_audience)
    :timer.sleep(2100)
    assert {:ok, nil} = EncryptedRedisTokenCache.get_token_for(@test_audience)
  end

  defp sample_token, do: %TokenInfo{jwt: "my-token", issued_at: one_hour_ago(), expires_at: in_one_hour()}
  defp token_key(audience), do: "auth0ex_tokens:#{namespace()}:#{audience}"
  defp in_two_seconds, do: Timex.now() |> Timex.shift(seconds: 2) |> Timex.to_unix()
  defp namespace, do: Application.fetch_env!(:auth0_ex, :client)[:cache_namespace]
end
