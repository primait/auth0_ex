defmodule PrimaAuth0Ex.TokenCache.NoopCacheTest do
  use ExUnit.Case, async: true

  import PrimaAuth0Ex.TestSupport.TimeUtils
  alias PrimaAuth0Ex.TokenCache.NoopCache
  alias PrimaAuth0Ex.TokenProvider.TokenInfo

  test "doesn't store tokens" do
    cached_token = %TokenInfo{jwt: "CACHED-TOKEN", issued_at: one_hour_ago(), expires_at: in_one_hour()}
    :ok = NoopCache.set_token_for(:noop_test_client, "audience", cached_token)
    {:ok, nil} = NoopCache.get_token_for(:noop_test_audience, "audience")
  end
end
