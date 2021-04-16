defmodule Auth0Ex.TokenProvider.EncryptedRedisTokenCache do
  @moduledoc """
  Implementation of `Auth0Ex.TokenProvider.TokenCache` that persists encrypted copies of tokens on Redis.

  Encryption-related functionalities are implemented in `Auth0Ex.TokenProvider.TokenEncryptor`.
  """

  require Logger
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
    key = key_for(audience)

    case Redix.command(Auth0Ex.Redix, ["GET", key]) do
      {:ok, nil} ->
        Logger.info("Token not found on redis.", audience: audience, key: key)
        {:ok, nil}

      {:ok, cached_value} ->
        parse_and_decrypt(cached_value)

      {:error, reason} ->
        Logger.warn("Error retrieving token from redis.", audience: audience, key: key, reason: reason)
        {:error, reason}
    end
  end

  defp do_set_token_for(audience, token) do
    with {:ok, json_token} <- to_json(token),
         {:ok, encrypted} <- TokenEncryptor.encrypt(json_token),
         do: save(encrypted, key_for(audience), token.expires_at)
  end

  defp key_for(audience), do: "auth0ex_tokens:#{namespace()}:#{audience}"

  defp save(token, audience, expires_at) do
    expires_in = expires_at - current_time()

    case Redix.command(Auth0Ex.Redix, ["SET", audience, token, "EX", expires_in]) do
      {:ok, _} ->
        Logger.info("Updated token on redis.", audience: audience)
        :ok

      {:error, reason} ->
        Logger.warn("Error updating token on redis.", reason: inspect(reason))
        {:error, reason}
    end
  end

  defp parse_and_decrypt(cached_value) do
    with {:ok, decrypted} <- TokenEncryptor.decrypt(cached_value),
         {:ok, token_attributes} <- Jason.decode(decrypted) do
      build_token(token_attributes)
    else
      {:error, message} ->
        Logger.warn("Found invalid data on redis.", message: inspect(message))
        {:error, message}
    end
  end

  defp to_json(token), do: Jason.encode(token)

  defp build_token(%{"jwt" => jwt, "issued_at" => issued_at, "expires_at" => expires_at}) do
    {:ok, %TokenInfo{jwt: jwt, issued_at: issued_at, expires_at: expires_at}}
  end

  defp build_token(_), do: {:error, :malformed_cached_data}

  defp enabled?, do: :auth0_ex |> Application.get_env(:client, []) |> Keyword.get(:cache_enabled, true)
  defp namespace, do: Application.fetch_env!(:auth0_ex, :client)[:cache_namespace]
  defp current_time, do: Timex.to_unix(Timex.now())
end
