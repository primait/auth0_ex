defmodule Auth0Ex do
  alias Auth0Ex.{Token, TokenProvider}

  @spec token_for(String.t()) :: String.t()
  def token_for(audience) do
    TokenProvider.token_for(TokenProvider, audience)
  end

  @spec verify_and_validate(String.t(), String.t() | nil, list(String.t())) ::
          {:ok, Joken.claims()} | {:error, atom | Keyword.t()}
  def verify_and_validate(token, audience \\ nil, permissions \\ []) do
    audience = audience || default_audience()
    Token.verify_and_validate_token(token, audience, permissions)
  end

  defp default_audience, do: Application.fetch_env!(:auth0_ex, :server)[:audience]
end
