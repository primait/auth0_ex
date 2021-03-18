defmodule Auth0Ex.Plug.VerifyAndValidateTokenTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Auth0Ex.Auth0Credentials
  alias Auth0Ex.Plug.VerifyAndValidateToken
  alias Auth0Ex.TestSupport.JwtUtils
  alias Auth0Ex.TokenProvider.Auth0AuthorizationService

  @test_audience "test"
  @opts VerifyAndValidateToken.init(audience: @test_audience)

  @tag :external
  test "does nothing when token is valid" do
    credentials = Auth0Credentials.from_env()
    {:ok, token} = Auth0AuthorizationService.retrieve_token(credentials, audience())

    conn =
      :get
      |> conn("/")
      |> put_req_header("authorization", "Bearer " <> token.jwt)
      |> VerifyAndValidateToken.call(VerifyAndValidateToken.init([]))

    refute conn.status == 401
  end

  test "returns 401 when no authorization header is set" do
    conn = :get |> conn("/") |> VerifyAndValidateToken.call(@opts)

    assert conn.status == 401
  end

  test "returns 401 when authorization header is invalid" do
    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "invalid")
      |> VerifyAndValidateToken.call(@opts)

    assert conn.status == 401
  end

  test "returns 401 when bearer token is not valid" do
    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer invalid-token")
      |> VerifyAndValidateToken.call(@opts)

    assert conn.status == 401
  end

  test "returns 401 when bearer token is not signed by the expected issuer" do
    locally_forged_token = JwtUtils.jwt_that_expires_in(3600, @test_audience)

    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer " <> locally_forged_token)
      |> VerifyAndValidateToken.call(@opts)

    assert conn.status == 401
  end

  @tag :external
  test "supports setting a custom audience for validation" do
    credentials = Auth0Credentials.from_env()
    {:ok, token} = Auth0AuthorizationService.retrieve_token(credentials, audience())

    opts = VerifyAndValidateToken.init(audience: "something-different-than-" <> audience())

    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer " <> token.jwt)
      |> VerifyAndValidateToken.call(opts)

    assert conn.status == 401
  end

  @tag :external
  test "supports setting required permissions" do
    credentials = Auth0Credentials.from_env()
    {:ok, token} = Auth0AuthorizationService.retrieve_token(credentials, audience())

    opts = VerifyAndValidateToken.init(required_permissions: ["permission-that-user-on-auth0-should-not-have"])

    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer " <> token.jwt)
      |> VerifyAndValidateToken.call(opts)

    assert conn.status == 401
  end

  test "supports disabling verification of signatures" do
    # mostly useful for dev environments, to work with locally forged JWTs
    forged_token = JwtUtils.jwt_that_expires_in(1_000, @test_audience)
    opts = VerifyAndValidateToken.init(audience: @test_audience, verify_signature: false)

    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer " <> forged_token)
      |> VerifyAndValidateToken.call(opts)

    refute conn.status == 401
  end

  test "can be run in dry-run mode (ie. not blocking invalid requests)" do
    opts = VerifyAndValidateToken.init(dry_run: true)

    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer invalid-jwt")
      |> VerifyAndValidateToken.call(opts)

    refute conn.status == 401
  end

  defp audience, do: Application.fetch_env!(:auth0_ex, :server)[:audience]
end
