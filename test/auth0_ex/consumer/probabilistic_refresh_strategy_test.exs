defmodule Auth0Ex.Consumer.ProbabilisticRefreshStrategyTest do
  use ExUnit.Case

  alias Auth0Ex.Consumer.ProbabilisticRefreshStrategy
  alias Auth0Ex.TestSupport.JwtUtils

  @hours 60 * 60

  test "should always refresh expired tokens" do
    assert true == ProbabilisticRefreshStrategy.should_refresh?(JwtUtils.expired_jwt())
  end

  test "should never refresh tokens when more than X time is remaining for expiration" do
    assert false == ProbabilisticRefreshStrategy.should_refresh?(JwtUtils.jwt_that_expires_in(24 * @hours))
  end

  test "returns either true or false when approaching expiration time, following a probabilistic distribution" do
    :rand.seed(:exsplus, 0)

    assert true == ProbabilisticRefreshStrategy.should_refresh?(JwtUtils.jwt_that_expires_in(1 * @hours))
    assert false == ProbabilisticRefreshStrategy.should_refresh?(JwtUtils.jwt_that_expires_in(11 * @hours))
  end
end
