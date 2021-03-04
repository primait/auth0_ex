defmodule Auth0Ex.Consumer.CachedTokenService do
  alias Auth0Ex.Consumer.TokenService

  @behaviour TokenService

  @authorization_service Application.compile_env!(:auth0_ex, :authorization_service)
  @token_cache Application.compile_env!(:auth0_ex, :token_cache)

  @impl TokenService
  def retrieve_token(credentials, audience) do
    token =
      audience
      |> @token_cache.get_token_for()
      |> refresh_token_on_cache_miss(credentials, audience)

    {:ok, token}
  end

  @impl TokenService
  def refresh_token(credentials, audience, current_token) do
    token =
      audience
      |> @token_cache.get_token_for()
      |> refresh_token_unless_it_changed(current_token, credentials, audience)

    {:ok, token}
  end

  defp refresh_token_on_cache_miss({:ok, nil}, credentials, audience) do
    {:ok, token} = @authorization_service.retrieve_token(credentials, audience)
    @token_cache.set_token_for(audience, token)
    token
  end

  defp refresh_token_on_cache_miss({:ok, cached_token}, _credentials, _audience), do: cached_token

  defp refresh_token_unless_it_changed({:ok, cached_token}, current_token, _, _) when cached_token != current_token do
    cached_token
  end

  defp refresh_token_unless_it_changed({:ok, _cached_token}, _, credentials, audience) do
    {:ok, token} = @authorization_service.retrieve_token(credentials, audience)
    @token_cache.set_token_for(audience, token)
    token
  end
end
