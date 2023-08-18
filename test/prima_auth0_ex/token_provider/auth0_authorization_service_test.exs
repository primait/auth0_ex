defmodule PrimaAuth0Ex.TokenProvider.Auth0AuthorizationServiceTest do
  use ExUnit.Case, async: true

  alias PrimaAuth0Ex.Auth0Credentials
  alias PrimaAuth0Ex.TestSupport.Counter
  alias PrimaAuth0Ex.TestSupport.JwtUtils
  alias PrimaAuth0Ex.TokenProvider.Auth0AuthorizationService

  @invalid_auth0_response ~s<{"error": "I am an invalid response from auth0"}>

  @test_audience "test"

  @sample_credentials %Auth0Credentials{
    client: :client,
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

  test "emits success event on obtaining a JWT from Auth0", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/oauth/token", fn conn ->
      Plug.Conn.resp(conn, 200, valid_auth0_response())
    end)

    credentials = %{@sample_credentials | base_url: "http://localhost:#{bypass.port}"}

    {:ok, counter} = Counter.start_link([])

    success_telemetry_handler_id = "success-telemetry-handler"

    :ok =
      :telemetry.attach(
        success_telemetry_handler_id,
        [:prima_auth0_ex, :retrieve_token, :success],
        fn
          [:prima_auth0_ex, :retrieve_token, :success], %{count: 1}, %{audience: @test_audience}, _config ->
            Counter.increment(counter)
        end,
        nil
      )

    {:ok, _token} = Auth0AuthorizationService.retrieve_token(credentials, @test_audience)

    :ok = :telemetry.detach(success_telemetry_handler_id)
  end

  test "emits failure event when failing to obtain a JWT from Auth0", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/oauth/token", fn conn ->
      Plug.Conn.resp(conn, 200, @invalid_auth0_response)
    end)

    credentials = %{@sample_credentials | base_url: "http://localhost:#{bypass.port}"}

    {:ok, counter} = Counter.start_link([])

    failure_telemetry_handler_id = "failure-telemetry-handler"

    :ok =
      :telemetry.attach(
        failure_telemetry_handler_id,
        [:prima_auth0_ex, :retrieve_token, :failure],
        fn
          [:prima_auth0_ex, :retrieve_token, :failure], %{count: 1}, %{audience: @test_audience}, _config ->
            Counter.increment(counter)
        end,
        nil
      )

    {:error, _error} = Auth0AuthorizationService.retrieve_token(credentials, @test_audience)

    :ok = :telemetry.detach(failure_telemetry_handler_id)
  end

  defp sample_token do
    JwtUtils.generate_fake_jwt(@test_audience, %{}, %{"kid" => "my-kid"})
  end

  defp valid_auth0_response, do: ~s<{"access_token":"#{sample_token()}","expires_in":86400,"token_type":"Bearer"}>
end
