defmodule PrimaAuth0Ex.TokenProvider.ProbabilisticRefreshStrategy do
  @moduledoc """
  Implementation of `PrimaAuth0Ex.TokenProvider.RefreshStrategy` that relies on a probabilistic approach
  to decide whether to refresh a token.

  The reason why a probabilistic approach is desirable is that multiple instances may share a common cache of tokens.
  If all of them used the same deterministic approach to decide when to refresh tokens,
  the likelihood of concurrent regeneration of the cached token would be higher.

  This strategy defines a "refresh window", which is a time span in the lifespan of a token when
  the refresh may happen (e.g., "from 50% to 75% of the life of the token").
  The refresh time will be a random time in the refresh window.

  The "refresh window" can be customized from config as follows

    config :prima_auth0_ex, :client,
      min_token_duration: 0.5,
      max_token_duration: 0.75,
  """

  alias PrimaAuth0Ex.TokenProvider.RefreshStrategy

  @behaviour RefreshStrategy

  @impl RefreshStrategy
  def refresh_time_for(client, token) do
    token_lifespan = token.expires_at - token.issued_at
    refresh_window_start = token.issued_at + trunc(token_lifespan * min_token_duration(client))
    refresh_window_end = token.issued_at + trunc(token_lifespan * max_token_duration(client))

    refresh_time = random_time_between(refresh_window_start, refresh_window_end)

    Timex.from_unix(refresh_time)
  end

  defp random_time_between(start, finish), do: Enum.random(start..finish)

  defp min_token_duration(client),
    do: :prima_auth0_ex |> Application.get_env(client, []) |> Keyword.get(:min_token_duration, 0.5)

  defp max_token_duration(client),
    do: :prima_auth0_ex |> Application.get_env(client, []) |> Keyword.get(:max_token_duration, 0.75)
end
