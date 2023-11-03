defmodule PrimaAuth0Ex.OpenIDConfigurationTest do
  use ExUnit.Case, async: true

  alias PrimaAuth0Ex.OpenIDConfiguration

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "Fetches and parses metadata from a server", %{bypass: bypass} do
    config = openid_configuration(bypass)

    Bypass.expect_once(bypass, "GET", "/.well-known/openid-configuration", fn conn ->
      Plug.Conn.resp(conn, 200, Jason.encode!(config))
    end)

    base_url = "http://localhost:#{bypass.port}"

    fetched = OpenIDConfiguration.fetch!(base_url)

    assert fetched.issuer == config.issuer
    assert fetched.token_endpoint == config.token_endpoint
    assert fetched.jwks_uri == config.jwks_uri
  end

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
