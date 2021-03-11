defmodule Auth0Ex do
  @moduledoc """
  Handles the retrieval of token from Auth0 and their verification/validation.
  """

  alias Auth0Ex.{Token, TokenProvider}

  @doc """
  Obtain a token for the given audience.
  """
  @spec token_for(String.t()) :: String.t()
  def token_for(audience) do
    TokenProvider.token_for(TokenProvider, audience)
  end

  @doc """
  Verify the integrity of a tokoen, and validate its claims.

  The audience to be validated can be set either from config or explicitly
  from the `audience` parameter.

  Additionally, it is possible to set a list of permissions to validate.
  Only tokens that include all the required permissions will pass validation.
  """
  @spec verify_and_validate(String.t(), String.t() | nil, list(String.t())) ::
          {:ok, Joken.claims()} | {:error, atom | Keyword.t()}
  def verify_and_validate(token, audience \\ nil, permissions \\ []) do
    audience = audience || default_audience()
    Token.verify_and_validate_token(token, audience, permissions)
  end

  defp default_audience, do: Application.fetch_env!(:auth0_ex, :server)[:audience]
end
