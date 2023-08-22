defmodule PrimaAuth0Ex.TokenProvider.CachedTokenService do
  @moduledoc """
  Implementation of `PrimaAuth0Ex.TokenProvider.TokenService` that caches tokens on
  an external cache in order to limit the requests made to Auth0 by reusing tokens.

  The external cache can be shared among different instances of the same service: in that
  case, when one of the instances refreshes the token and updates the shared cache, the other
  instances will retrieve the new token from the new cache and will not have to generate a new
  one from the authorization provider.
  """
  alias PrimaAuth0Ex.Config

  alias PrimaAuth0Ex.TokenProvider.{
    Auth0AuthorizationService,
    EncryptedRedisTokenCache,
    TokenService
  }

  @behaviour TokenService

  @impl TokenService
  def retrieve_token(credentials, audience) do
    credentials.client
    |> token_cache().get_token_for(audience)
    |> refresh_token_on_cache_miss(credentials, audience)
  end

  @impl TokenService
  def refresh_token(credentials, audience, current_token, false = _force_cache_bust) do
    credentials.client
    |> token_cache().get_token_for(audience)
    |> refresh_token_unless_it_changed(current_token, credentials, audience)
  end

  def refresh_token(credentials, audience, _current_token, true = _force_cache_bust) do
    do_refresh_token(credentials, audience)
  end

  defp refresh_token_on_cache_miss(result, credentials, audience)

  defp refresh_token_on_cache_miss({:error, _}, credentials, audience),
    do: do_refresh_token(credentials, audience)

  defp refresh_token_on_cache_miss({:ok, nil}, credentials, audience),
    do: do_refresh_token(credentials, audience)

  defp refresh_token_on_cache_miss({:ok, cached_token}, _, _), do: {:ok, cached_token}

  defp refresh_token_unless_it_changed(result, token, credentials, audience)

  defp refresh_token_unless_it_changed({:error, _}, _, credentials, audience) do
    do_refresh_token(credentials, audience)
  end

  defp refresh_token_unless_it_changed({:ok, nil}, _, credentials, audience) do
    do_refresh_token(credentials, audience)
  end

  defp refresh_token_unless_it_changed({:ok, cached_token}, current_token, _, _)
       when cached_token != current_token do
    {:ok, cached_token}
  end

  defp refresh_token_unless_it_changed({:ok, _cached_token}, _, credentials, audience) do
    do_refresh_token(credentials, audience)
  end

  defp do_refresh_token(credentials, audience) do
    case authorization_service().retrieve_token(credentials, audience) do
      {:ok, token} ->
        token_cache().set_token_for(credentials.client, audience, token)
        {:ok, token}

      {:error, description} ->
        {:error, description}
    end
  end

  defp authorization_service,
    do: Config.authorization_service(Auth0AuthorizationService)

  defp token_cache, do: Config.token_cache(EncryptedRedisTokenCache)
end
