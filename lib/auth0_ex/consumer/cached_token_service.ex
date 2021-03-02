defmodule Auth0Ex.Consumer.CachedTokenService do
  alias Auth0Ex.Consumer.TokenService

  @behaviour TokenService

  @authorization_service Application.compile_env!(:auth0_ex, :authorization_service)
  @token_cache Application.compile_env!(:auth0_ex, :token_cache)

  @impl TokenService
  def retrieve_token(credentials, audience) do
    token =
      case @token_cache.get_token_for(audience) do
        {:ok, token} ->
          token

        {:error, :not_found} ->
          {:ok, token} = @authorization_service.retrieve_token(credentials, audience)
          @token_cache.set_token_for(audience, token)
          token
      end

    {:ok, token}
  end

  @impl TokenService
  def refresh_token(credentials, audience, current_token) do
    {:ok, cached_token} = @token_cache.get_token_for(audience)

    token = if cached_token == current_token do
      {:ok, token} = @authorization_service.retrieve_token(credentials, audience)
      @token_cache.set_token_for(audience, token)
      token
    else
      cached_token
    end

    {:ok, token}
  end
end
