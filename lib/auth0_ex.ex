defmodule Auth0Ex do
  alias Auth0Ex.TokenProvider

  def token_for(audience) do
    TokenProvider.token_for(TokenProvider, audience)
  end
end
