defmodule Auth0Ex.Consumer.EncryptedRedisTokenCache do
  alias Auth0Ex.Consumer.{TokenEncryptor, TokenCache}

  @behaviour TokenCache

  @cache_namespace Application.compile_env!(:auth0_ex, :cache_namespace)

  @impl TokenCache
  def get_token_for(audience) do
    case Redix.command(:redix, ["GET", key_for(audience)]) do
      {:ok, nil} -> {:ok, nil}
      {:ok, encrypted_token} -> {:ok, TokenEncryptor.decrypt(encrypted_token)}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl TokenCache
  def set_token_for(audience, token) do
    token
    |> TokenEncryptor.encrypt()
    |> save(key_for(audience))
  end

  defp key_for(audience), do: "auth0ex_tokens:#{@cache_namespace}:#{audience}"

  defp save(value, key) do
    Redix.command(:redix, ["SET", key, value])
  end
end
