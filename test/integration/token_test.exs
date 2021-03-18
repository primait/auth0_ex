defmodule Integration.TokenTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.TestSupport.JwtUtils
  alias Auth0Ex.Token
  alias Auth0Ex.TokenProvider.Auth0AuthorizationService

  @tag :external
  test "verifies token obtained from auth0" do
    credentials = Auth0Ex.Auth0Credentials.from_env()
    {:ok, auth0_token} = Auth0AuthorizationService.retrieve_token(credentials, audience())

    assert {:ok, _} = Token.verify_and_validate_token(auth0_token.jwt, audience(), [])
  end

  test "does not verify other tokens" do
    audience = "test"
    locally_forged_token = JwtUtils.jwt_that_expires_in(10_000, audience)

    assert {:error, _} = Token.verify_and_validate_token(locally_forged_token, audience, [])
  end

  defp audience, do: Application.fetch_env!(:auth0_ex, :server)[:audience]
end
