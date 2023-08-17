defmodule Integration.Auth0AuthorizationServiceTest do
  use ExUnit.Case, async: true

  alias PrimaAuth0Ex.TokenProvider.{Auth0AuthorizationService, TokenInfo}

  @test_client_name :test_client

  @tag :external
  test "obtains a JWT from Auth0" do
    credentials = PrimaAuth0Ex.Auth0Credentials.from_env(@test_client_name)
    audience = Application.fetch_env!(:prima_auth0_ex, :server)[:audience]

    {:ok, token} = Auth0AuthorizationService.retrieve_token(credentials, audience)

    assert is_struct(token, TokenInfo)
    assert {:ok, %{"alg" => "RS256", "kid" => _kid, "typ" => "JWT"}} = Joken.peek_header(token.jwt)
  end

  @tag :external
  test "obtains a JWT from Auth0 using the default client" do
    credentials = PrimaAuth0Ex.Auth0Credentials.from_env()
    audience = Application.fetch_env!(:prima_auth0_ex, :server)[:audience]

    {:ok, token} = Auth0AuthorizationService.retrieve_token(credentials, audience)

    assert is_struct(token, TokenInfo)
    assert {:ok, %{"alg" => "RS256", "kid" => _kid, "typ" => "JWT"}} = Joken.peek_header(token.jwt)
  end
end
