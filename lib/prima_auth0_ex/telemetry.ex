if Code.ensure_loaded?(Statix) do
  defmodule PrimaAuth0Ex.Telemetry.Statix do
    @moduledoc """
    A pre-defined Statix module
    """

    use Statix, runtime_config: true

    def setup do
      :ok =
        :telemetry.attach_many(
          "auth0-handler",
          [
            [:prima_auth0_ex, :retrieve_token, :failure],
            [:prima_auth0_ex, :retrieve_token, :success]
          ],
          &PrimaAuth0Ex.Telemetry.Handler.handle_event/4,
          nil
        )

      :ok = PrimaAuth0Ex.Telemetry.Statix.connect()
    end
  end

  defmodule PrimaAuth0Ex.Telemetry.Handler do
    @moduledoc """
    A pre-defined Statix telemetry handler
    """

    alias PrimaAuth0Ex.Telemetry.Statix

    def handle_event([:prima_auth0_ex, :retrieve_token, :failure], %{count: count}, %{audience: audience}, _config) do
      Statix.increment("retrieve_token:failure", count, tags: ["audience:#{audience}"])
    end

    def handle_event([:prima_auth0_ex, :retrieve_token, :success], %{count: count}, %{audience: audience}, _config) do
      Statix.increment("retrieve_token:success", count, tags: ["audience:#{audience}"])
    end
  end
end
