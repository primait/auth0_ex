defmodule Auth0Ex.Consumer.EncryptedRedisTokenCacheTest do
  use ExUnit.Case

  alias Auth0Ex.Consumer.EncryptedRedisTokenCache

  setup do
    Redix.start_link(name: :redix)
    :ok
  end

  test "persists and retrieves tokens" do
    EncryptedRedisTokenCache.set_token_for("audience", "token")

    assert {:ok, "token"} == EncryptedRedisTokenCache.get_token_for("audience")
  end
end
