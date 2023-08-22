defmodule PrimaAuth0Ex.Telemetry do
  @moduledoc """
  A pre-defined module which sets up telemetry with a given reporter
  """

  alias PrimaAuth0Ex.Config
  alias PrimaAuth0Ex.Telemetry.Handler

  @auth0_handler_id "auth0-handler"

  def setup do
    reporter = telemetry_reporter()

    if reporter != nil do
      :ok =
        :telemetry.attach_many(
          @auth0_handler_id,
          [
            [:prima_auth0_ex, :retrieve_token, :failure],
            [:prima_auth0_ex, :retrieve_token, :success]
          ],
          &Handler.handle_event/4,
          %{reporter: reporter}
        )
    end
  end

  defp telemetry_reporter, do: Config.telemetry_reporter()
end

defmodule PrimaAuth0Ex.Telemetry.Handler do
  @moduledoc """
  A pre-defined telemetry handler
  """

  def handle_event(
        [:prima_auth0_ex, :retrieve_token, status],
        %{count: count},
        %{audience: audience},
        %{reporter: reporter}
      ) do
    reporter.increment("auth0.token", count, tags: ["audience:#{audience}", "status:#{status}"])
  end
end
