defmodule PrimaAuth0Ex.LocalTokenTest do
  use ExUnit.Case, async: true

  alias PrimaAuth0Ex.Config
  alias PrimaAuth0Ex.LocalToken
  alias PrimaAuth0Ex.TestSupport.TimeUtils

  test "forges a token for the given audience" do
    jwt = LocalToken.forge("audience")

    assert %{"aud" => "audience"} = claims_of(jwt)
  end

  test "default issuing time is in the past" do
    jwt = LocalToken.forge("audience")
    %{"iat" => issued_at} = claims_of(jwt)

    assert DateTime.before?(DateTime.from_unix!(issued_at), DateTime.utc_now())
  end

  test "default expiration time is in the future" do
    jwt = LocalToken.forge("audience")
    %{"exp" => expires_at} = claims_of(jwt)

    assert DateTime.after?(DateTime.from_unix!(expires_at), DateTime.utc_now())
  end

  test "default issuer is the same configured for the server" do
    expected_issuer = Config.server!(:issuer)

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

    assert DateTime.before?(DateTime.from_unix!(expires_at), DateTime.utc_now())
  end

  test "time_from_now/1 allows to easily create unix timestamps" do
    one_hour_ago = LocalToken.time_from_now(hour: -1)

    assert DateTime.before?(DateTime.from_unix!(one_hour_ago), DateTime.utc_now())
    assert one_hour_ago > LocalToken.time_from_now(minute: -61)
    assert one_hour_ago < LocalToken.time_from_now(minute: -59)
  end

  defp claims_of(jwt) do
    {:ok, claims} = Joken.peek_claims(jwt)
    claims
  end
end
