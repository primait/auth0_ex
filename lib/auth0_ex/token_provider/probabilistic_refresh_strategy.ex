defmodule Auth0Ex.TokenProvider.ProbabilisticRefreshStrategy do
  alias Auth0Ex.TokenProvider.RefreshStrategy

  @behaviour RefreshStrategy

  @impl RefreshStrategy
  def should_refresh?(token) do
    token_lifespan = token.expires_at - token.issued_at

    refresh_window_start = token.issued_at + trunc(token_lifespan * min_token_duration())
    refresh_window_end = token.issued_at + trunc(token_lifespan * max_token_duration())

    probabilistic_choice(current_time(), refresh_window_start, refresh_window_end)
  end

  defp probabilistic_choice(current_time, refresh_window_start, refresh_window_end) do
    refresh_window_duration = refresh_window_end - refresh_window_start

    # always false when current_time < refresh_window_start
    # always true when current_time > refresh_window_end
    # otherwise, it gets more likely the more we approach refresh_window_end
    :rand.uniform(refresh_window_duration) < current_time - refresh_window_start
  end

  defp current_time, do: Timex.to_unix(Timex.now())
  defp min_token_duration, do: Application.fetch_env!(:auth0_ex, :client)[:min_token_duration]
  defp max_token_duration, do: Application.fetch_env!(:auth0_ex, :client)[:max_token_duration]
end
