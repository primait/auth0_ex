defmodule Auth0Ex.Consumer.ProbabilisticRefreshStrategy do
  alias Auth0Ex.Consumer.RefreshStrategy

  @behaviour RefreshStrategy

  @hours 60 * 60
  @refresh_window_duration_seconds 12 * @hours

  @impl RefreshStrategy
  def should_refresh?(token) do
    case seconds_to_expiration(token) do
      s when s < 0 -> true
      s when s > @refresh_window_duration_seconds -> false
      s -> probabilistic_choice(s)
    end
  end

  defp seconds_to_expiration(token) do
    {:ok, %{"exp" => expiration_time}} = Joken.peek_claims(token)

    expiration_time - Joken.current_time()
  end

  defp probabilistic_choice(seconds_to_expiration) do
    # gets more likely the more we approach expiration time
    :rand.uniform(@refresh_window_duration_seconds) > seconds_to_expiration
  end
end
