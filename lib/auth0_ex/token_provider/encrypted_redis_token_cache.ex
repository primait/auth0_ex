defmodule Auth0Ex.TokenProvider.EncryptedRedisTokenCache do
  alias Auth0Ex.TokenProvider.{TokenCache, TokenEncryptor, TokenInfo}

  @behaviour TokenCache

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
      {:ok, cached_value} -> parse_and_decrypt(cached_value)
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_set_token_for(audience, token) do
    token
    |> to_json()
    |> TokenEncryptor.encrypt()
    |> save(key_for(audience), token.expires_at)
  end

  defp key_for(audience), do: "auth0ex_tokens:#{namespace()}:#{audience}"

  defp save(value, key, expires_at) do
    case Redix.command(:redix, ["SET", key, value, "EXAT", expires_at]) do
      {:ok, _} -> :ok
      {:error, description} -> {:error, description}
    end
  end

  defp parse_and_decrypt(cached_value) do
    with decrypted <- TokenEncryptor.decrypt(cached_value),
         {:ok, token_attributes} <- Jason.decode(decrypted),
         {:ok, token} <- build_token(token_attributes),
         do: {:ok, token}
  end

  defp to_json(token), do: Jason.encode!(token)

  defp build_token(%{"jwt" => jwt, "issued_at" => issued_at, "expires_at" => expires_at}) do
    {:ok, %TokenInfo{jwt: jwt, issued_at: issued_at, expires_at: expires_at}}
  end

  defp build_token(_), do: {:error, :malformed_cached_data}

  defp enabled?, do: Application.fetch_env!(:auth0_ex, :cache)[:enabled]
  defp namespace, do: Application.fetch_env!(:auth0_ex, :cache)[:namespace]
end
