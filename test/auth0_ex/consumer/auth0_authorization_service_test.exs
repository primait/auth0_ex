defmodule Auth0Ex.Consumer.Auth0AuthorizationServiceTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.Auth0Credentials
  alias Auth0Ex.Consumer.Auth0AuthorizationService

  @valid_auth0_response ~s<{"access_token":"my-token","expires_in":86400,"token_type":"Bearer"}>
  @invalid_auth0_response ~s<{"error": "I am an invalid response from auth0"}>

  @sample_credentials %Auth0Credentials{
    base_url: "http://localhost",
    client_id: "client_id",
    client_secret: "client_secret"
  }

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "returns JWT obtained from Auth0", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/oauth/token", fn conn ->
      Plug.Conn.resp(conn, 200, @valid_auth0_response)
    end)

    credentials = %{@sample_credentials | base_url: "http://localhost:#{bypass.port}"}

    {:ok, _token} = Auth0AuthorizationService.retrieve_token(credentials, "audience")
  end

  test "returns error :invalid_auth0_response on unexpected response from Auth0",
       %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/oauth/token", fn conn ->
      Plug.Conn.resp(conn, 200, @invalid_auth0_response)
    end)

    credentials = %{@sample_credentials | base_url: "http://localhost:#{bypass.port}"}

    {:error, :invalid_auth0_response} =
      Auth0AuthorizationService.retrieve_token(credentials, "audience")
  end

  test "returns error :request_error if request to Auth0 is not successful", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/oauth/token", fn conn ->
      Plug.Conn.resp(conn, 500, "any response")
    end)

    credentials = %{@sample_credentials | base_url: "http://localhost:#{bypass.port}"}

    {:error, :request_error} = Auth0AuthorizationService.retrieve_token(credentials, "audience")
  end
end