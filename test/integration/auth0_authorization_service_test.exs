defmodule Integration.Auth0AuthorizationServiceTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.Consumer.Auth0AuthorizationService

  test "obtains a JWT from Auth0" do
    credentials = Auth0Ex.Auth0Credentials.from_env()
    audience = Application.fetch_env!(:auth0_ex, :auth0)[:default_audience]

    {:ok, token} = Auth0AuthorizationService.retrieve_token(credentials, audience)

    assert {:ok, %{"alg" => "RS256", "kid" => _kid, "typ" => "JWT"}} = Joken.peek_header(token)
  end
end
