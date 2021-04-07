defmodule Auth0Ex.LocalTokenTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.LocalToken
  alias Auth0Ex.TestSupport.TimeUtils

  test "forges a token for the given audience" do
    jwt = LocalToken.forge("audience")

    assert %{"aud" => "audience"} = claims_of(jwt)
  end

  test "default issuing time is in the past" do
    jwt = LocalToken.forge("audience")
    %{"iat" => issued_at} = claims_of(jwt)

    assert Timex.before?(Timex.from_unix(issued_at), Timex.now())
  end

  test "default expiration time is in the future" do
    jwt = LocalToken.forge("audience")
    %{"exp" => expires_at} = claims_of(jwt)

    assert Timex.after?(Timex.from_unix(expires_at), Timex.now())
  end

  test "default issuer is the same configured for the server" do
    expected_issuer = Application.fetch_env!(:auth0_ex, :server)[:issuer]

    jwt = LocalToken.forge("audience")
    %{"iss" => issuer} = claims_of(jwt)

    assert expected_issuer == issuer
  end

  test "by default no permission is set" do
    jwt = LocalToken.forge("audience")

    refute Map.has_key?(claims_of(jwt), "permissions")
  end

  test "allows overriding default claims" do
    jwt = LocalToken.forge("audience", exp: TimeUtils.one_hour_ago())

    %{"exp" => expires_at} = claims_of(jwt)

    assert Timex.before?(Timex.from_unix(expires_at), Timex.now())
  end

  defp claims_of(jwt) do
    {:ok, claims} = Joken.peek_claims(jwt)
    claims
  end
end
