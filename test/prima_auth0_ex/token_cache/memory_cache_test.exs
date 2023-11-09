defmodule Integration.TokenCache.MemoryCacheTest do
  use ExUnit.Case, async: true

  import PrimaAuth0Ex.TestSupport.TimeUtils
  alias PrimaAuth0Ex.TokenProvider.TokenInfo
  alias PrimaAuth0Ex.TokenCache.MemoryCache

  @client :memory_cache_client
  @test_audience "memory-cache-test-audience"

  setup do
    cache_env = Application.get_env(:prima_auth0_ex, :memory_cache, nil)

    on_exit(fn ->
      Application.put_env(:prima_auth0_ex, :memory_cache, cache_env)
    end)

    Application.put_env(:prima_auth0_ex, :memory_cache, cleanup_interval: 25)
    start_supervised!(MemoryCache)
    :ok
  end

  test "persists and retrieves tokens" do
    token = sample_token()
    :ok = MemoryCache.set_token_for(@client, @test_audience, token)

    assert {:ok, token} == MemoryCache.get_token_for(@client, @test_audience)
  end

  test "returns {:ok, nil} when token is not cached" do
    assert {:ok, nil} == MemoryCache.get_token_for(@client, @test_audience)
  end

  test "tokens are deleted from cache when they expire" do
    Application.put_env(:prima_auth0_ex, :memory_cache, cleanup_interval: 25)
    stop_supervised!(MemoryCache)
    start_supervised!(MemoryCache)

    token = %TokenInfo{sample_token() | expires_at: shifted_by_seconds(2)}
    :ok = MemoryCache.set_token_for(@client, @test_audience, token)

    assert {:ok, ^token} = MemoryCache.get_token_for(@client, @test_audience)
    :timer.sleep(2100)
    assert {:ok, nil} = MemoryCache.get_token_for(@client, @test_audience)
  end

  defp sample_token do
    %TokenInfo{
      jwt: "my-token",
      issued_at: one_hour_ago(),
      expires_at: in_one_hour(),
      kid: "my-kid"
    }
  end
end
