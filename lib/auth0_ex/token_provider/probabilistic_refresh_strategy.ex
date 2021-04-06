defmodule Auth0Ex.TokenProvider.ProbabilisticRefreshStrategy do
  @moduledoc """
  Implementation of `Auth0Ex.TokenProvider.RefreshStrategy` that relies on a probabilistic approach
  to decide whether to refresh a token.

  The reason why a probabilistic approach is desirable is that multiple instances may share a common cache of tokens.
  If all of them used the same deterministic approach to decide when to refresh tokens,
  the likelihood of concurrent regeneration of the cached token would be higher.

  This strategy defines a "refresh window", which is a time span in the lifespan of a token when
  the refresh may happen (e.g., "from 50% to 75% of the life of the token").
  Probability of a refresh is 0 until the refresh window begins, then it keeps increasing as time passes.

  The "refresh window" can be customized from config as follows

    config :auth0_ex, :client,
      min_token_duration: 0.5,
      max_token_duration: 0.75,
  """

  alias Auth0Ex.TokenProvider.RefreshStrategy

  # @behaviour RefreshStrategy

  # @impl RefreshStrategy
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
  defp min_token_duration, do: :auth0_ex |> Application.get_env(:client, []) |> Keyword.get(:min_token_duration, 0.5)
  defp max_token_duration, do: :auth0_ex |> Application.get_env(:client, []) |> Keyword.get(:max_token_duration, 0.75)
end
