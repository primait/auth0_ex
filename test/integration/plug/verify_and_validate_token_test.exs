defmodule Auth0Ex.Plug.VerifyAndValidateTokenTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Auth0Ex.Plug.VerifyAndValidateToken
  alias Auth0Ex.TestSupport.JwtUtils

  test "does nothing when token is valid" do
    credentials = Auth0Ex.Auth0Credentials.from_env()
    audience = Application.fetch_env!(:auth0_ex, :auth0)[:audience]
    {:ok, token} = Auth0Ex.TokenProvider.Auth0AuthorizationService.retrieve_token(credentials, audience)

    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer " <> token)
      |> VerifyAndValidateToken.call(%{})

    refute conn.status == 401
  end

  test "returns 401 when no authorization header is set" do
    conn = conn(:get, "/") |> VerifyAndValidateToken.call(%{})

    assert conn.status == 401
  end

  test "returns 401 when authorization header is invalid" do
    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "invalid")
      |> VerifyAndValidateToken.call(%{})

    assert conn.status == 401
  end

  test "returns 401 when bearer token is not valid" do
    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer invalid-token")
      |> VerifyAndValidateToken.call(%{})

    assert conn.status == 401
  end

  test "returns 401 when bearer token is not signed by the expected issuer" do
    locally_forged_token = JwtUtils.jwt_that_expires_in(3600)

    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer " <> locally_forged_token)
      |> VerifyAndValidateToken.call(%{})

    assert conn.status == 401
  end
end
