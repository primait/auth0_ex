defmodule Integration.TokenCache.MemoryCacheTest do
  alias PrimaAuth0Ex.TokenCache.MemoryCache

  use PrimaAuth0Ex.TestSupport.TokenCacheBehaviorCaseTemplate, async: true, cache_module: MemoryCache
  setup_all do
    Application.put_env(:prima_auth0_ex, :memory_cache, cleanup_interval: 25)
  end

  setup do
    cache_env = Application.get_env(:prima_auth0_ex, :memory_cache)

    on_exit(fn ->
      if cache_env == nil do
        Application.delete_env(:prima_auth0_ex, :memory_cache)
      else
        Application.put_env(:prima_auth0_ex, :memory_cache, cache_env)
      end
    end)

    start_supervised!(MemoryCache)
    :ok
  end
end
