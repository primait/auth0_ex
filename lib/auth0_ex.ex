defmodule Auth0Ex do
  alias Auth0Ex.{Token, TokenProvider}

  def token_for(audience) do
    TokenProvider.token_for(TokenProvider, audience)
  end

  def verify_and_validate(token, audience \\ nil, permissions \\ []) do
    audience = audience || default_audience()
    Token.verify_and_validate_token(token, audience, permissions)
  end

  defp default_audience, do: Application.fetch_env!(:auth0_ex, :server)[:audience]
end
