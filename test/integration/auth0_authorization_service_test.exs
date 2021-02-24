defmodule Integration.Auth0AuthorizationServiceTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.Consumer.Auth0AuthorizationService

  test "obtains a JWT from Auth0" do
    domain = Application.fetch_env!(:auth0_ex, :auth0)[:base_url]
    audience = Application.fetch_env!(:auth0_ex, :auth0)[:default_audience]
    client_id = Application.fetch_env!(:auth0_ex, :auth0)[:client_id]
    client_secret = Application.fetch_env!(:auth0_ex, :auth0)[:client_secret]

    {:ok, token} =
      Auth0AuthorizationService.retrieve_token(domain, client_id, client_secret, audience)

    assert {:ok, %{"alg" => "RS256", "kid" => _kid, "typ" => "JWT"}} = Joken.peek_header(token)
  end
end
