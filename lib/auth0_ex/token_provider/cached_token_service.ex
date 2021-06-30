defmodule Auth0Ex.TokenProvider.CachedTokenService do
  @moduledoc """
  Implementation of `Auth0Ex.TokenProvider.TokenService` that caches tokens on
  an external cache in order to limit the requests made to Auth0 by reusing tokens.

  The external cache can be shared among different instances of the same service: in that
  case, when one of the instances refreshes the token and updates the shared cache, the other
  instances will retrieve the new token from the new cache and will not have to generate a new
  one from the authorization provider.
  """
  alias Auth0Ex.TokenProvider.{Auth0AuthorizationService, EncryptedRedisTokenCache, TokenService}

  @behaviour TokenService

  @authorization_service Application.compile_env(:auth0_ex, :authorization_service, Auth0AuthorizationService)
  @token_cache Application.compile_env(:auth0_ex, :token_cache, EncryptedRedisTokenCache)

  @impl TokenService
  def retrieve_token(credentials, audience) do
    audience
    |> @token_cache.get_token_for()
    |> refresh_token_on_cache_miss(credentials, audience)
  end

  @impl TokenService
  def refresh_token(credentials, audience, current_token, _force_cache_bust = false) do
    audience
    |> @token_cache.get_token_for()
    |> refresh_token_unless_it_changed(current_token, credentials, audience)
  end

  def refresh_token(credentials, audience, _current_token, _force_cache_bust = true) do
    do_refresh_token(credentials, audience)
  end

  defp refresh_token_on_cache_miss({:error, _}, credentials, audience), do: do_refresh_token(credentials, audience)
  defp refresh_token_on_cache_miss({:ok, nil}, credentials, audience), do: do_refresh_token(credentials, audience)
  defp refresh_token_on_cache_miss({:ok, cached_token}, _credentials, _audience), do: {:ok, cached_token}

  defp refresh_token_unless_it_changed({:error, _}, _, credentials, audience) do
    do_refresh_token(credentials, audience)
  end

  defp refresh_token_unless_it_changed({:ok, nil}, _, credentials, audience) do
    do_refresh_token(credentials, audience)
  end

  defp refresh_token_unless_it_changed({:ok, cached_token}, current_token, _, _) when cached_token != current_token do
    {:ok, cached_token}
  end

  defp refresh_token_unless_it_changed({:ok, _cached_token}, _, credentials, audience) do
    do_refresh_token(credentials, audience)
  end

  defp do_refresh_token(credentials, audience) do
    case @authorization_service.retrieve_token(credentials, audience) do
      {:ok, token} ->
        @token_cache.set_token_for(audience, token)
        {:ok, token}

      {:error, description} ->
        {:error, description}
    end
  end
end
