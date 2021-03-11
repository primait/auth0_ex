defmodule Auth0Ex.TokenProvider.EncryptedRedisTokenCacheTest do
  use ExUnit.Case

  alias Auth0Ex.TokenProvider.{EncryptedRedisTokenCache, TokenInfo}

  @namespace Application.compile_env!(:auth0_ex, :cache)[:namespace]
  @sample_token %TokenInfo{jwt: "my-token", issued_at: 123, expires_at: 234}

  setup do
    redis_connection_uri = Application.fetch_env!(:auth0_ex, :cache)[:redis_connection_uri]
    Redix.start_link(redis_connection_uri, name: :redix)
    Redix.command!(:redix, ["DEL", token_key("audience")])

    :ok
  end

  test "persists and retrieves tokens" do
    :ok = EncryptedRedisTokenCache.set_token_for("audience", @sample_token)

    assert {:ok, @sample_token} == EncryptedRedisTokenCache.get_token_for("audience")
  end

  test "returns {:ok, nil} when token is not cached" do
    assert {:ok, nil} == EncryptedRedisTokenCache.get_token_for("audience")
  end

  test "encrypts tokens" do
    :ok = EncryptedRedisTokenCache.set_token_for("audience", @sample_token)

    persisted_token = Redix.command!(:redix, ["GET", token_key("audience")])

    assert is_binary(persisted_token)
    assert {:error, _} = Jason.decode(persisted_token)
  end

  defp token_key(audience), do: "auth0ex_tokens:#{@namespace}:#{audience}"
end
