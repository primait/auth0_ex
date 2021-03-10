defmodule Auth0Ex.TokenProvider.ProbabilisticRefreshStrategy do
  alias Auth0Ex.TokenProvider.RefreshStrategy

  @behaviour RefreshStrategy

  @impl RefreshStrategy
  def should_refresh?(token) do
    {issued_at, expires_at} = peek_token_claims(token)
    token_lifespan = expires_at - issued_at

    refresh_window_start = issued_at + trunc(token_lifespan * min_token_duration())
    refresh_window_end = issued_at + trunc(token_lifespan * max_token_duration())

    current_time = Joken.current_time()

    probabilistic_choice(current_time, refresh_window_start, refresh_window_end)
  end

  defp peek_token_claims(token) do
    {:ok, %{"iat" => issued_at, "exp" => expires_at}} = Joken.peek_claims(token)

    {issued_at, expires_at}
  end

  defp probabilistic_choice(current_time, refresh_window_start, refresh_window_end) do
    refresh_window_duration = refresh_window_end - refresh_window_start

    # always false when current_time < refresh_window_start
    # always true when current_time > refresh_window_end
    # otherwise, it gets more likely the more we approach refresh_window_end
    :rand.uniform(refresh_window_duration) < current_time - refresh_window_start
  end

  defp min_token_duration, do: Application.fetch_env!(:auth0_ex, :min_token_duration)
  defp max_token_duration, do: Application.fetch_env!(:auth0_ex, :max_token_duration)
end
