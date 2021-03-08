defmodule Auth0Ex.TokenTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.Token

  @one_day 24 * 60 * 60

  test "a token is valid if all its claims pass validation" do
    assert {:ok, _} = Token.validate(valid_token_claims())
  end

  test "a token is not valid when its expiration date has passed" do
    expired_token_claims = %{valid_token_claims() | "exp" => Joken.current_time() - @one_day}

    assert {:error, _} = Token.validate(expired_token_claims)
  end

  test "a token is not valid when its 'not-before-date' is in the future" do
    not_yet_valid_token_claims = %{valid_token_claims() | "nbf" => Joken.current_time() + @one_day}

    assert {:error, _} = Token.validate(not_yet_valid_token_claims)
  end

  test "a token is not valid if its audience is different than the configured one" do
    claims_for_wrong_audience = %{valid_token_claims() | "aud" => "something-different-than-" <> audience()}

    assert {:error, _} = Token.validate(claims_for_wrong_audience)
  end

  test "a token is not valid if its issuer is different than the configured one" do
    claims_with_wrong_issuer = %{valid_token_claims() | "iss" => "something-different-than-" <> issuer()}

    assert {:error, _} = Token.validate(claims_with_wrong_issuer)
  end

  defp valid_token_claims do
    %{
      "aud" => audience(),
      "exp" => Joken.current_time() + @one_day,
      "iat" => Joken.current_time() - @one_day,
      "iss" => issuer(),
      "nbf" => Joken.current_time() - @one_day
    }
  end

  defp audience, do: Application.fetch_env!(:auth0_ex, :auth0)[:audience]
  defp issuer, do: Application.fetch_env!(:auth0_ex, :auth0)[:issuer]
end
