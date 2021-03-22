defmodule Auth0Ex.TokenProvider.ProbabilisticRefreshStrategyTest do
  use ExUnit.Case, async: true

  import Auth0Ex.TestSupport.TimeUtils
  alias Auth0Ex.TokenProvider.{ProbabilisticRefreshStrategy, TokenInfo}

  @hours 60 * 60

  test "should always refresh expired tokens" do
    expired_token = %TokenInfo{jwt: "any", issued_at: two_hours_ago(), expires_at: one_hour_ago()}

    assert true == ProbabilisticRefreshStrategy.should_refresh?(expired_token)
  end

  test "should never refresh new tokens" do
    new_token = %TokenInfo{jwt: "any", issued_at: now(), expires_at: in_two_hours()}

    assert false == ProbabilisticRefreshStrategy.should_refresh?(new_token)
  end

  test "returns either true or false when approaching expiration time" do
    :rand.seed(:exsplus, 0)

    old_jwt = %TokenInfo{jwt: "any", issued_at: now() - 23 * @hours, expires_at: in_one_hour()}
    recent_jwt = %TokenInfo{jwt: "any", issued_at: one_hour_ago(), expires_at: now() + 23 * @hours}

    assert true == ProbabilisticRefreshStrategy.should_refresh?(old_jwt)
    assert false == ProbabilisticRefreshStrategy.should_refresh?(recent_jwt)
  end
end
