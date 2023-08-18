defmodule Integration.Auth0AuthorizationServiceTest do
  use ExUnit.Case, async: true

  alias PrimaAuth0Ex.TokenProvider.{Auth0AuthorizationService, TokenInfo}

  @tag :external
  test "obtains a JWT from Auth0" do
    credentials = PrimaAuth0Ex.Auth0Credentials.from_env()
    audience = Application.fetch_env!(:prima_auth0_ex, :server)[:audience]

    {:ok, token} = Auth0AuthorizationService.retrieve_token(credentials, audience)

    assert is_struct(token, TokenInfo)
    assert {:ok, %{"alg" => "RS256", "kid" => _kid, "typ" => "JWT"}} = Joken.peek_header(token.jwt)
  end
end
