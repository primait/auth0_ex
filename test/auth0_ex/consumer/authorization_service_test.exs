defmodule Auth0Ex.Consumer.AuthorizationServiceTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.Consumer.AuthorizationService

  test "obtains a JWT from auth0" do
    {:ok, token} = AuthorizationService.retrieve_token()

    assert {:ok, %{"alg" => "RS256", "kid" => _kid, "typ" => "JWT"}} = Joken.peek_header(token)
  end
end
