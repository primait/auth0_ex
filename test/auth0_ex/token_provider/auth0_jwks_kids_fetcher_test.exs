defmodule Auth0Ex.TokenProvider.AuthJwksKidsFetcherTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.Auth0Credentials
  alias Auth0Ex.TokenProvider.Auth0JwksKidsFetcher

  @auth0_jwks_api_path "/.well-known/jwks.json"
  @sample_credentials %Auth0Credentials{
    base_url: "http://localhost",
    client_id: "client_id",
    client_secret: "client_secret"
  }

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  @tag capture_log: true
  test "returns error when request fails", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", @auth0_jwks_api_path, fn conn ->
      Plug.Conn.resp(conn, 500, "")
    end)

    credentials = %{@sample_credentials | base_url: "http://localhost:#{bypass.port}"}
    assert {:error, _} = Auth0JwksKidsFetcher.fetch_kids(credentials)
  end

  @tag capture_log: true
  test "returns error when response does not contain valid JSON", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", @auth0_jwks_api_path, fn conn ->
      Plug.Conn.resp(conn, 200, "not json")
    end)

    credentials = %{@sample_credentials | base_url: "http://localhost:#{bypass.port}"}
    assert {:error, _} = Auth0JwksKidsFetcher.fetch_kids(credentials)
  end

  @tag capture_log: true
  test "returns error when response does not contain a valid JWKS", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", @auth0_jwks_api_path, fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"invalid": "jwks"}))
    end)

    credentials = %{@sample_credentials | base_url: "http://localhost:#{bypass.port}"}
    assert {:error, _} = Auth0JwksKidsFetcher.fetch_kids(credentials)
  end
end
