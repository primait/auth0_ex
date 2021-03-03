defmodule Auth0Ex.Consumer.EncryptedRedisTokenCache do
  alias Auth0Ex.Consumer.TokenCache

  @behaviour TokenCache

  @cache_namespace Application.compile_env!(:auth0_ex, :redix_instance_name)
  @redix_instance_name Application.compile_env!(:auth0_ex, :redix_instance_name)
  @token_encryption_secret Application.fetch_env!(:auth0_ex, :token_encryption_secret)

  @impl TokenCache
  def get_token_for(audience) do
    {:ok, token} = Redix.command(:redix, ["GET", key_for(audience)])
    {:ok, token}
  end

  @impl TokenCache
  def set_token_for(audience, token) do
    Redix.command!(:redix, ["SET", key_for(audience), token])
    :ok
  end

  defp key_for(audience), do: "auth0ex_tokens:#{@cache_namespace}:#{audience}"
end
