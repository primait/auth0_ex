defmodule Auth0Ex.Consumer.EncryptedRedisTokenCacheTest do
  use ExUnit.Case

  alias Auth0Ex.Consumer.EncryptedRedisTokenCache

  @cache_namespace Application.compile_env!(:auth0_ex, :redix_instance_name)

  setup do
    Redix.start_link(name: :redix)
    :ok
  end

  test "persists and retrieves tokens" do
    EncryptedRedisTokenCache.set_token_for("audience", "token")

    assert {:ok, "token"} == EncryptedRedisTokenCache.get_token_for("audience")
  end

  test "encrypts tokens" do
    EncryptedRedisTokenCache.set_token_for("audience", "token")

    persisted_token = Redix.command!(:redix, ["GET", token_key("audience")])

    assert is_binary(persisted_token)
    assert persisted_token != "token"
  end

  defp token_key(audience), do: "auth0ex_tokens:#{@cache_namespace}:#{audience}"
end
