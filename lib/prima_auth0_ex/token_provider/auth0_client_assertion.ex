defmodule PrimaAuth0Ex.TokenProvider.Auth0ClientAssertion do
  @moduledoc """
  Builds the signed client assertion used by Auth0's `private_key_jwt` method.

  The 60-second assertion lifetime follows Auth0's recommendation; it is not a
  protocol-mandated value. The caller supplies the issuer from OpenID metadata
  as the assertion audience.
  """

  alias PrimaAuth0Ex.Auth0Credentials

  @assertion_lifetime_seconds 60
  @jose_algorithms %{rs256: "RS256", rs384: "RS384", ps256: "PS256"}

  @spec generate(Auth0Credentials.t(), String.t()) ::
          {:ok, String.t()}
          | {:error, Joken.error_reason()}
          | {:error, {:unsupported_signing_algorithm, Auth0Credentials.signing_algorithm()}}
          | {:error, :missing_private_key}
  def generate(%Auth0Credentials{private_key: nil}, _issuer), do: {:error, :missing_private_key}
  def generate(%Auth0Credentials{private_key: ""}, _issuer), do: {:error, :missing_private_key}

  def generate(%Auth0Credentials{} = credentials, issuer) do
    case Map.fetch(@jose_algorithms, credentials.signing_algorithm) do
      {:ok, jose_algorithm} -> generate(credentials, issuer, jose_algorithm)
      :error -> {:error, {:unsupported_signing_algorithm, credentials.signing_algorithm}}
    end
  end

  defp generate(credentials, issuer, jose_algorithm) do
    headers = if credentials.private_key_id, do: %{"kid" => credentials.private_key_id}, else: %{}

    signer =
      Joken.Signer.create(
        jose_algorithm,
        %{"pem" => credentials.private_key},
        headers
      )

    issued_at = Joken.current_time()

    claims = %{
      "aud" => issuer,
      "exp" => issued_at + @assertion_lifetime_seconds,
      "iat" => issued_at,
      "iss" => credentials.client_id,
      "jti" => UUID.uuid4(),
      "sub" => credentials.client_id
    }

    Joken.Signer.sign(claims, signer)
  end
end
