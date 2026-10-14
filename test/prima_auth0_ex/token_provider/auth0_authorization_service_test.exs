defmodule PrimaAuth0Ex.TokenProvider.Auth0AuthorizationServiceTest do
  use ExUnit.Case, async: true

  alias PrimaAuth0Ex.Auth0Credentials
  alias PrimaAuth0Ex.TestSupport.Counter
  alias PrimaAuth0Ex.TestSupport.JwtUtils
  alias PrimaAuth0Ex.TokenProvider.Auth0AuthorizationService

  @invalid_auth0_response ~s<{"error": "I am an invalid response from auth0"}>

  @test_audience "test"

  @sample_credentials %Auth0Credentials{
    client: :default_client,
    base_url: "http://localhost",
    client_id: "client_id",
    client_secret: "client_secret"
  }

  setup_all do
    {:ok, _started_apps} = Application.ensure_all_started(:bypass)
    {:ok, _started_apps} = Application.ensure_all_started(:hackney)

    rsa_private_key = :public_key.generate_key({:rsa, 2048, 65_537})
    pem_entry = :public_key.pem_entry_encode(:RSAPrivateKey, rsa_private_key)
    private_key = :public_key.pem_encode([pem_entry])

    {:ok, private_key: private_key}
  end

  setup do
    bypass = Bypass.open()

    Bypass.stub(bypass, "GET", "/.well-known/openid-configuration", fn conn ->
      Plug.Conn.resp(conn, 200, Jason.encode!(openid_configuration(bypass)))
    end)

    {:ok, bypass: bypass}
  end

  test "uses a private key assertion instead of the client secret", %{
    bypass: bypass,
    private_key: private_key
  } do
    Bypass.expect_once(bypass, "POST", "/oauth/token", fn conn ->
      {:ok, request_body, conn} = Plug.Conn.read_body(conn)
      request = Jason.decode!(request_body)

      assert request["grant_type"] == "client_credentials"

      assert request["client_assertion_type"] ==
               "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"

      assert request["audience"] == @test_audience
      refute Map.has_key?(request, "client_secret")
      assert is_binary(request["client_assertion"])

      signer = Joken.Signer.create("RS256", %{"pem" => private_key})
      assert {:ok, claims} = Joken.Signer.verify(request["client_assertion"], signer)
      assert claims["iss"] == "client_id"
      assert claims["sub"] == "client_id"
      assert claims["aud"] == "https://tenant.eu.auth0.com/"

      Plug.Conn.resp(conn, 200, valid_auth0_response())
    end)

    credentials = %{
      @sample_credentials
      | base_url: "http://localhost:#{bypass.port}",
        client_secret: nil,
        authentication_method: :private_key_jwt,
        private_key: private_key
    }

    {:ok, _token} = Auth0AuthorizationService.retrieve_token(credentials, @test_audience)
  end

  test "returns JWT obtained from Auth0", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/oauth/token", fn conn ->
      {:ok, request_body, conn} = Plug.Conn.read_body(conn)

      assert Jason.decode!(request_body) == %{
               "grant_type" => "client_credentials",
               "client_id" => "client_id",
               "client_secret" => "client_secret",
               "audience" => @test_audience
             }

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

  defp openid_configuration(bypass) do
    %{
      issuer: "https://tenant.eu.auth0.com/",
      authorization_endpoint: "http://localhost:#{bypass.port}/oauth/login",
      token_endpoint: "http://localhost:#{bypass.port}/oauth/token",
      jwks_uri: "http://localhost:#{bypass.port}/jwks.json",
      response_types_supported: [
        "token id_token"
      ],
      subject_types_supported: [
        "public"
      ],
      id_token_signing_alg_values_supported: [
        "RS256"
      ]
    }
  end
end
