defmodule Auth0Ex.TokenProvider.ProbabilisticRefreshStrategyTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.TokenProvider.ProbabilisticRefreshStrategy
  alias Auth0Ex.TestSupport.JwtUtils

  @hours 60 * 60

  test "should always refresh expired tokens" do
    assert true == ProbabilisticRefreshStrategy.should_refresh?(JwtUtils.expired_jwt())
  end

  test "should never refresh new tokens" do
    new_token = test_jwt(current_time(), current_time() + 12 * @hours)

    assert false == ProbabilisticRefreshStrategy.should_refresh?(new_token)
  end

  test "returns either true or false when approaching expiration time" do
    :rand.seed(:exsplus, 0)

    old_jwt = test_jwt(current_time() - 23 * @hours, current_time() + 1 * @hours)
    recent_jwt = test_jwt(current_time() - 1 * @hours, current_time() + 23 * @hours)

    assert true == ProbabilisticRefreshStrategy.should_refresh?(old_jwt)
    assert false == ProbabilisticRefreshStrategy.should_refresh?(recent_jwt)
  end

  defp current_time, do: Joken.current_time()
  defp test_jwt(issued_at, expires_at), do: JwtUtils.jwt_with_claims(%{"iat" => issued_at, "exp" => expires_at})
end
