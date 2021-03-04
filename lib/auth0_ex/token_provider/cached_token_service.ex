defmodule Auth0Ex.TokenProvider.CachedTokenService do
  alias Auth0Ex.TokenProvider.TokenService

  @behaviour TokenService

  @authorization_service Application.compile_env!(:auth0_ex, :authorization_service)
  @token_cache Application.compile_env!(:auth0_ex, :token_cache)

  @impl TokenService
  def retrieve_token(credentials, audience) do
    audience
    |> @token_cache.get_token_for()
    |> refresh_token_on_cache_miss(credentials, audience)
  end

  @impl TokenService
  def refresh_token(credentials, audience, current_token) do
    audience
    |> @token_cache.get_token_for()
    |> refresh_token_unless_it_changed(current_token, credentials, audience)
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
