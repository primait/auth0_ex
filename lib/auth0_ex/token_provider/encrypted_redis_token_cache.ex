defmodule Auth0Ex.TokenProvider.EncryptedRedisTokenCache do
  alias Auth0Ex.TokenProvider.{TokenEncryptor, TokenCache}

  @behaviour TokenCache

  @namespace Application.compile_env!(:auth0_ex, :cache)[:namespace]

  @impl TokenCache
  def get_token_for(audience) do
    if enabled?(), do: do_get_token_for(audience), else: {:ok, nil}
  end

  @impl TokenCache
  def set_token_for(audience, token) do
    if enabled?(), do: do_set_token_for(audience, token), else: :ok
  end

  defp do_get_token_for(audience) do
    case Redix.command(:redix, ["GET", key_for(audience)]) do
      {:ok, nil} -> {:ok, nil}
      {:ok, encrypted_token} -> {:ok, TokenEncryptor.decrypt(encrypted_token)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_set_token_for(audience, token) do
    token
    |> TokenEncryptor.encrypt()
    |> save(key_for(audience))
  end

  defp key_for(audience), do: "auth0ex_tokens:#{@namespace}:#{audience}"

  defp save(value, key) do
    Redix.command(:redix, ["SET", key, value])
  end

  defp enabled?, do: Application.fetch_env!(:auth0_ex, :cache)[:enabled]
end
