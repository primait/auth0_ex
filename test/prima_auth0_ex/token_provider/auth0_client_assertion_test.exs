defmodule PrimaAuth0Ex.TokenProvider.Auth0ClientAssertionTest do
  use ExUnit.Case, async: true

  alias PrimaAuth0Ex.Auth0Credentials
  alias PrimaAuth0Ex.TokenProvider.Auth0ClientAssertion

  setup_all do
    rsa_private_key = :public_key.generate_key({:rsa, 2048, 65_537})
    pem_entry = :public_key.pem_entry_encode(:RSAPrivateKey, rsa_private_key)
    private_key = :public_key.pem_encode([pem_entry])

    {:ok, private_key: private_key}
  end

  test "generates a signed assertion with Auth0 client claims and key id", %{
    private_key: private_key
  } do
    credentials = credentials(private_key, "auth0-key-id")

    assert {:ok, assertion} =
             Auth0ClientAssertion.generate(credentials, "https://tenant.eu.auth0.com/")

    assert [encoded_header, _encoded_claims, _signature] = String.split(assertion, ".")
    assert {:ok, header_json} = Base.url_decode64(encoded_header, padding: false)
    assert {:ok, header} = Jason.decode(header_json)
    assert header == %{"alg" => "RS256", "kid" => "auth0-key-id", "typ" => "JWT"}

    signer = Joken.Signer.create("RS256", %{"pem" => private_key})
    assert {:ok, claims} = Joken.Signer.verify(assertion, signer)

    assert claims["iss"] == credentials.client_id
    assert claims["sub"] == credentials.client_id
    assert claims["aud"] == "https://tenant.eu.auth0.com/"
    assert claims["exp"] - claims["iat"] == 60
    assert String.match?(claims["jti"], ~r/\A[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/)
  end

  test "omits the key id header when none is configured", %{private_key: private_key} do
    credentials = credentials(private_key, nil)

    assert {:ok, assertion} =
             Auth0ClientAssertion.generate(credentials, "https://tenant.eu.auth0.com/")

    assert [encoded_header, _encoded_claims, _signature] = String.split(assertion, ".")
    assert {:ok, header_json} = Base.url_decode64(encoded_header, padding: false)
    assert {:ok, header} = Jason.decode(header_json)
    refute Map.has_key?(header, "kid")
  end

  test "maps the configured algorithm atom to the JOSE header", %{private_key: private_key} do
    credentials = %{credentials(private_key, nil) | signing_algorithm: :rs384}

    assert {:ok, assertion} =
             Auth0ClientAssertion.generate(credentials, "https://tenant.eu.auth0.com/")

    assert [encoded_header, _encoded_claims, _signature] = String.split(assertion, ".")
    assert {:ok, header_json} = Base.url_decode64(encoded_header, padding: false)
    assert {:ok, header} = Jason.decode(header_json)
    assert header["alg"] == "RS384"
  end

  test "returns an error when the private key is missing" do
    credentials = credentials(nil, nil)

    assert {:error, :missing_private_key} =
             Auth0ClientAssertion.generate(credentials, "https://tenant.eu.auth0.com/")
  end

  defp credentials(private_key, private_key_id) do
    %Auth0Credentials{
      client: :default_client,
      base_url: "https://tenant.eu.auth0.com",
      client_id: "client-id",
      client_secret: nil,
      authentication_method: :private_key_jwt,
      private_key: private_key,
      private_key_id: private_key_id
    }
  end
end
