defmodule Auth0Ex.TokenTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.Token

  @audience "some-audience"
  @one_day 24 * 60 * 60

  test "a token is valid if all its claims pass validation" do
    assert {:ok, _} = Token.validate(valid_token_claims(), %{audience: @audience})
  end

  test "when permissions are required, a token is valid if its permissions are a superset of the required ones" do
    claims_with_valid_permissions =
      valid_token_claims()
      |> Map.put("permissions", ["1st:perm", "2nd:perm", "3rd:perm", "4th:perm"])

    assert {:ok, _} =
             Token.validate(
               claims_with_valid_permissions,
               %{audience: @audience, required_permissions: ["2nd:perm", "3rd:perm"]}
             )
  end

  test "a token is not valid when its expiration date has passed" do
    expired_token_claims = %{valid_token_claims() | "exp" => Joken.current_time() - @one_day}

    assert {:error, _} = Token.validate(expired_token_claims, %{audience: @audience})
  end

  test "a token is not valid when its 'not-before-date' is in the future" do
    not_yet_valid_token_claims = %{valid_token_claims() | "nbf" => Joken.current_time() + @one_day}

    assert {:error, _} = Token.validate(not_yet_valid_token_claims, %{audience: @audience})
  end

  test "a token is not valid if its audience is different than the configured one" do
    claims_for_wrong_audience = %{valid_token_claims() | "aud" => "something-different-than-" <> @audience}

    assert {:error, _} = Token.validate(claims_for_wrong_audience, %{audience: @audience})
  end

  test "a token is not valid if its issuer is different than the configured one" do
    claims_with_wrong_issuer = %{valid_token_claims() | "iss" => "something-different-than-" <> issuer()}

    assert {:error, _} = Token.validate(claims_with_wrong_issuer, %{audience: @audience})
  end

  test "a token is not valid if it does not contain all required permissions" do
    claims_with_wrong_permissions = Map.put(valid_token_claims(), "permissions", ["1st:perm"])

    assert {:error, _} =
             Token.validate(
               claims_with_wrong_permissions,
               %{audience: @audience, required_permissions: ["1st:perm", "2nd:perm"]}
             )
  end

  test "expected audience can be customized by passing it in context" do
    a_different_audience = "something-different-than-" <> @audience

    assert {:error, _} = Token.validate(valid_token_claims(), %{audience: a_different_audience})

    assert {:ok, _} =
             Token.validate(
               %{valid_token_claims() | "aud" => a_different_audience},
               %{audience: a_different_audience}
             )
  end

  defp valid_token_claims do
    %{
      "aud" => @audience,
      "exp" => Joken.current_time() + @one_day,
      "iat" => Joken.current_time() - @one_day,
      "iss" => issuer(),
      "nbf" => Joken.current_time() - @one_day
    }
  end

  defp issuer, do: Application.fetch_env!(:auth0_ex, :auth0)[:issuer]
end
