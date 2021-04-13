defmodule Integration.Auth0TokenVerifierTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.TokenProvider.{Auth0AuthorizationService, Auth0TokenVerifier, TokenInfo}

  @tag :external
  test "a token issued by Auth0 has valid signature" do
    credentials = Auth0Ex.Auth0Credentials.from_env()
    audience = Application.fetch_env!(:auth0_ex, :server)[:audience]

    {:ok, auth0_token} = Auth0AuthorizationService.retrieve_token(credentials, audience)

    assert Auth0TokenVerifier.signature_valid?(auth0_token)
  end

  test "a locally forged token has invalid signature" do
    local_token = forge_token()

    refute Auth0TokenVerifier.signature_valid?(local_token)
  end

  defp forge_token() do
    %TokenInfo{jwt: Auth0Ex.LocalToken.forge("some-audience"), issued_at: 0, expires_at: 0}
  end
end
