defmodule PrimaAuth0Ex.Plug.VerifyAndValidateTokenTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias PrimaAuth0Ex.Auth0Credentials
  alias PrimaAuth0Ex.Config
  alias PrimaAuth0Ex.Plug.VerifyAndValidateToken
  alias PrimaAuth0Ex.TestSupport.JwtUtils
  alias PrimaAuth0Ex.TokenProvider.Auth0AuthorizationService

  @moduletag capture_log: true

  @test_audience "test"
  @opts VerifyAndValidateToken.init(audience: @test_audience, required_permissions: [])

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

  test "raise a runtime error when required_permissions is not set" do
    assert_raise(RuntimeError, fn -> VerifyAndValidateToken.init(audience: audience()) end)
  end

  @tag :external
  test "supports setting a custom audience for validation" do
    credentials = Auth0Credentials.from_env()
    {:ok, token} = Auth0AuthorizationService.retrieve_token(credentials, audience())

    opts =
      VerifyAndValidateToken.init(
        audience: "something-different-than-" <> audience(),
        required_permissions: []
      )

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

    opts =
      VerifyAndValidateToken.init(
        required_permissions: ["permission-that-user-on-auth0-should-not-have"]
      )

    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer " <> token.jwt)
      |> VerifyAndValidateToken.call(opts)

    assert conn.status == 401
  end

  test "supports disabling verification of signatures" do
    # mostly useful for dev environments, to work with locally forged JWTs
    forged_token = JwtUtils.jwt_that_expires_in(1_000, @test_audience)

    opts =
      VerifyAndValidateToken.init(
        audience: @test_audience,
        ignore_signature: true,
        required_permissions: []
      )

    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer " <> forged_token)
      |> VerifyAndValidateToken.call(opts)

    refute conn.status == 401
  end

  test "can be run in dry-run mode (ie. not blocking invalid requests)" do
    opts = VerifyAndValidateToken.init(dry_run: true, required_permissions: [])

    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer invalid-jwt")
      |> VerifyAndValidateToken.call(opts)

    refute conn.status == 401
  end

  defp audience, do: Config.server!(:audience)
end
