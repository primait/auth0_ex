defmodule PrimaAuth0Ex.TokenProvider.ProbabilisticRefreshStrategyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import PrimaAuth0Ex.TestSupport.TimeUtils
  alias PrimaAuth0Ex.TokenProvider.{ProbabilisticRefreshStrategy, TokenInfo}

  @days 24 * 60 * 60

  @test_client :test_client

  test "refresh time is randomic" do
    token = %TokenInfo{jwt: "ignored", issued_at: one_hour_ago(), expires_at: in_one_hour()}

    assert ProbabilisticRefreshStrategy.refresh_time_for(@test_client, token) !=
             ProbabilisticRefreshStrategy.refresh_time_for(@test_client, token)
  end

  property "refresh always happens during the lifetime of the token" do
    check all(
            issued_at <- integer((now() - 30 * @days)..now()),
            expires_at <- integer((now() + 1 * @days)..(now() + 30 * @days))
          ) do
      token = %TokenInfo{jwt: "ignored", issued_at: issued_at, expires_at: expires_at}

      refresh_time = ProbabilisticRefreshStrategy.refresh_time_for(@test_client, token)

      assert Timex.after?(refresh_time, Timex.from_unix(issued_at))
      assert Timex.before?(refresh_time, Timex.from_unix(expires_at))
    end
  end
end
