defmodule Integration.TokenCache.EncryptedRedisTokenCacheTest do
  import ExUnit.CaptureLog
  import PrimaAuth0Ex.TestSupport.TimeUtils

  alias PrimaAuth0Ex.Config
  alias PrimaAuth0Ex.TokenCache.EncryptedRedisTokenCache
  alias PrimaAuth0Ex.TokenProvider.TokenInfo

  use PrimaAuth0Ex.TestSupport.TokenCacheBehaviorCaseTemplate,
    async: false,
    cache_module: EncryptedRedisTokenCache

  setup_all do
    start_supervised(EncryptedRedisTokenCache)
    :ok
  end

  setup do
    Redix.command!(PrimaAuth0Ex.Redix, ["DEL", token_key(test_audience())])

    redis_env = Application.fetch_env!(:prima_auth0_ex, :redis)
    cache_env = Application.fetch_env!(:prima_auth0_ex, :token_cache)
    Application.put_env(:prima_auth0_ex, :token_cache, EncryptedRedisTokenCache)

    on_exit(fn ->
      Application.put_env(:prima_auth0_ex, :redis, redis_env)
      Application.put_env(:prima_auth0_ex, :token_cache, cache_env)
    end)

    :ok
  end

  describe "logs on token encryption failure while setting token" do
    test "malformed token" do
      log =
        capture_log(fn ->
          EncryptedRedisTokenCache.set_token_for(test_audience(), <<0x80>>)
        end)

      assert String.match?(log, ~r/reason=/)
      assert String.contains?(log, "audience=#{test_audience()}")
      assert String.match?(log, ~r/Error setting token on redis./)
    end

    test "wrong cache_encryption_key" do
      put_redis_config(encryption_key: "abcd")

      log =
        capture_log(fn ->
          EncryptedRedisTokenCache.set_token_for(test_audience(), sample_token())
        end)

      assert String.match?(log, ~r/reason=/)
      assert String.contains?(log, "audience=#{test_audience()}")
      assert String.match?(log, ~r/Error setting token on redis./)
    end
  end

  test "retrieves tokens set by a previous version of prima_auth0_ex, hence without kid" do
    issued_at = one_hour_ago()
    expires_at = in_one_hour()
    token_without_kid = %{jwt: "my-token", issued_at: issued_at, expires_at: expires_at}
    :ok = EncryptedRedisTokenCache.set_token_for(test_audience(), token_without_kid)

    assert {:ok, %TokenInfo{jwt: "my-token", issued_at: ^issued_at, expires_at: ^expires_at, kid: nil}} =
             EncryptedRedisTokenCache.get_token_for(test_audience())
  end

  test "encrypts tokens" do
    :ok = EncryptedRedisTokenCache.set_token_for(test_audience(), sample_token())

    persisted_token = Redix.command!(PrimaAuth0Ex.Redix, ["GET", token_key(test_audience())])

    assert is_binary(persisted_token)
    assert {:error, _} = Jason.decode(persisted_token)
  end

  @tag capture_log: true
  test "returns error when persisted tokens are invalid and could not be decrypted" do
    # this may happen e.g., if the secret key changes
    Redix.command!(PrimaAuth0Ex.Redix, [
      "SET",
      token_key(test_audience()),
      "malformed-encrypted-token"
    ])

    assert {:error, _} = EncryptedRedisTokenCache.get_token_for(test_audience())
  end

  defp token_key(audience), do: "#{namespace()}:prima_auth0_ex_tokens:#{audience}"
  defp namespace, do: Config.default_client!(:cache_namespace)

  defp put_redis_config(new_conf) do
    config =
      :prima_auth0_ex
      |> Application.get_env(:redis)
      |> Keyword.merge(new_conf)

    Application.put_env(
      :prima_auth0_ex,
      :redis,
      config
    )
  end
end
