defmodule Auth0Ex.TokenTest do
  use ExUnit.Case, async: true

  import Auth0Ex.TestSupport.TimeUtils
  alias Auth0Ex.Token

  @audience "some-audience"

  test "a token is valid if all its claims pass validation" do
    assert {:ok, _} = Token.validate(valid_token_claims(), %{audience: @audience})
  end

  test "a valid token can have multiple audiences" do
    assert {:ok, _} = Token.validate(%{valid_token_claims() | "aud" => [@audience, "other"]}, %{audience: @audience})
  end

  test "when permissions are required, a token is valid if its permissions are a superset of the required ones" do
    claims_with_valid_permissions =
      Map.put(valid_token_claims(), "permissions", ["1st:perm", "2nd:perm", "3rd:perm", "4th:perm"])

    assert {:ok, _} =
             Token.validate(
               claims_with_valid_permissions,
               %{audience: @audience, required_permissions: ["2nd:perm", "3rd:perm"]}
             )
  end

  test "when permissions are required, a token is not valid if it does not have a permissions claim" do
    claims_without_permissions = valid_token_claims()

    assert {:error, _} =
             Token.validate(
               claims_without_permissions,
               %{audience: @audience, required_permissions: ["some:permission"]}
             )
  end

  test "when permissions are not required, a token is valid if it does not have a permissions claim" do
    claims_without_permissions = valid_token_claims()

    assert {:ok, _} =
             Token.validate(
               claims_without_permissions,
               %{audience: @audience, required_permissions: []}
             )
  end

  test "a token is not valid when its expiration date has passed" do
    expired_token_claims = %{valid_token_claims() | "exp" => one_hour_ago()}

    assert {:error, _} = Token.validate(expired_token_claims, %{audience: @audience})
  end

  test "a token is not valid when its 'not-before-date' is in the future" do
    not_yet_valid_token_claims = %{valid_token_claims() | "nbf" => in_one_hour()}

    assert {:error, _} = Token.validate(not_yet_valid_token_claims, %{audience: @audience})
  end

  test "a token is not valid if it has a single audience and it is different than the configured one" do
    claims_for_wrong_audience = %{valid_token_claims() | "aud" => "something-different-than-" <> @audience}

    assert {:error, _} = Token.validate(claims_for_wrong_audience, %{audience: @audience})
  end

  test "a token is not valid if it has multiple audiences and no one matches the configured one" do
    claims_for_wrong_audience = %{valid_token_claims() | "aud" => ["something-different-than-" <> @audience, "other"]}

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
      "exp" => in_one_hour(),
      "iat" => one_hour_ago(),
      "iss" => issuer(),
      "nbf" => one_hour_ago()
    }
  end

  defp issuer, do: Application.fetch_env!(:auth0_ex, :server)[:issuer]
end
