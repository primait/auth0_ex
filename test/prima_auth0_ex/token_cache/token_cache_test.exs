defmodule PrimaAuth0Ex.TokenCache.TokenCacheTest do
  use ExUnit.Case, async: false

  alias PrimaAuth0Ex.TokenCache

  setup do
    saved_cache_config = Application.get_env(:prima_auth0_ex, :cache)

    on_exit(fn ->
      Application.put_env(:prima_auth0_ex, :cache, saved_cache_config)
    end)
  end

  test "picks the right cache provider based on configuration" do
    Application.put_env(:prima_auth0_ex, :token_cache, EncryptedRedisTokenCache)
    PrimaAuth0Ex.TokenCache.EncryptedRedisTokenCache = TokenCache.get_configured_cache_provider()

    Application.put_env(:prima_auth0_ex, :token_cache, NoopCache)
    PrimaAuth0Ex.TokenCache.NoopCache = TokenCache.get_configured_cache_provider()

    Application.put_env(:prima_auth0_ex, :token_cache, Non.Existent)
    Non.Existent = TokenCache.get_configured_cache_provider()
  end
end
