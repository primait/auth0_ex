defmodule Auth0Ex.TokenProvider.EncryptedRedisTokenCacheTest do
  use ExUnit.Case

  alias Auth0Ex.TokenProvider.EncryptedRedisTokenCache

  @namespace Application.compile_env!(:auth0_ex, :cache)[:namespace]

  setup do
    redis_connection_uri = Application.fetch_env!(:auth0_ex, :cache)[:redis_connection_uri]
    Redix.start_link(redis_connection_uri, name: :redix)
    Redix.command!(:redix, ["DEL", token_key("audience")])

    :ok
  end

  test "persists and retrieves tokens" do
    EncryptedRedisTokenCache.set_token_for("audience", "token")

    assert {:ok, "token"} == EncryptedRedisTokenCache.get_token_for("audience")
  end

  test "returns {:ok, nil} when token is not cached" do
    assert {:ok, nil} == EncryptedRedisTokenCache.get_token_for("audience")
  end

  test "encrypts tokens" do
    EncryptedRedisTokenCache.set_token_for("audience", "token")

    persisted_token = Redix.command!(:redix, ["GET", token_key("audience")])

    assert is_binary(persisted_token)
    assert persisted_token != "token"
  end

  defp token_key(audience), do: "auth0ex_tokens:#{@namespace}:#{audience}"
end
