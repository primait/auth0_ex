defmodule PrimaAuth0Ex.TokenProvider.Auth0AuthorizationServiceTest do
  use ExUnit.Case, async: true

  alias PrimaAuth0Ex.Auth0Credentials
  alias PrimaAuth0Ex.TestSupport.JwtUtils
  alias PrimaAuth0Ex.TokenProvider.Auth0AuthorizationService

  @invalid_auth0_response ~s<{"error": "I am an invalid response from auth0"}>

  @sample_credentials %Auth0Credentials{
    base_url: "http://localhost",
    client_id: "client_id",
    client_secret: "client_secret"
  }

  @test_audience "test"

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "returns JWT obtained from Auth0", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/oauth/token", fn conn ->
      Plug.Conn.resp(conn, 200, valid_auth0_response())
    end)

    credentials = %{@sample_credentials | base_url: "http://localhost:#{bypass.port}"}

    {:ok, _token} = Auth0AuthorizationService.retrieve_token(credentials, @test_audience)
  end

  @tag capture_log: true
  test "returns error :invalid_auth0_response on unexpected response from Auth0",
       %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/oauth/token", fn conn ->
      Plug.Conn.resp(conn, 200, @invalid_auth0_response)
    end)

    credentials = %{@sample_credentials | base_url: "http://localhost:#{bypass.port}"}

    {:error, :invalid_auth0_response} = Auth0AuthorizationService.retrieve_token(credentials, "audience")
  end

  @tag capture_log: true
  test "returns error :request_error if request to Auth0 is not successful", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/oauth/token", fn conn ->
      Plug.Conn.resp(conn, 500, "any response")
    end)

    credentials = %{@sample_credentials | base_url: "http://localhost:#{bypass.port}"}

    {:error, :request_error} = Auth0AuthorizationService.retrieve_token(credentials, "audience")
  end

  defp sample_token do
    JwtUtils.generate_fake_jwt(@test_audience, %{}, %{"kid" => "my-kid"})
  end

  defp valid_auth0_response, do: ~s<{"access_token":"#{sample_token()}","expires_in":86400,"token_type":"Bearer"}>
end
