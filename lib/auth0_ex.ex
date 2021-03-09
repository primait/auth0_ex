defmodule Auth0Ex do
  alias Auth0Ex.{Token, TokenProvider}

  def token_for(audience) do
    TokenProvider.token_for(TokenProvider, audience)
  end

  def verify_and_validate(token) do
    Token.verify_and_validate(token)
  end
end
