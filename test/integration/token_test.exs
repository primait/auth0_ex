defmodule Integration.TokenTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.Token
  alias Auth0Ex.TokenProvider.Auth0AuthorizationService
  alias Auth0Ex.TestSupport.JwtUtils

  test "verifies token obtained from auth0" do
    credentials = Auth0Ex.Auth0Credentials.from_env()
    audience = Application.fetch_env!(:auth0_ex, :auth0)[:default_audience]
    {:ok, auth0_token} = Auth0AuthorizationService.retrieve_token(credentials, audience)

    assert {:ok, _} = Token.verify_and_validate(auth0_token)
  end

  test "does not verify other tokens" do
    locally_forged_token = JwtUtils.jwt_that_expires_in(10000)

    assert {:error, _} = Token.verify_and_validate(locally_forged_token)
  end
end
