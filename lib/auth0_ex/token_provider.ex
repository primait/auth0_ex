defmodule Auth0Ex.TokenProvider do
  @moduledoc """
  GenServer that handles the storage and refresh of tokens.

  Every time a token for a new audience is requested, it retrieves it either from a cache (when possible)
  or from an authorization provider.
  Then, it runs periodic checks to ensure that all tokens are still valid, and it refreshes them when necessary.
  """

  use GenServer

  require Logger
  alias Auth0Ex.TokenProvider.{CachedTokenService, ProbabilisticRefreshStrategy, TokenInfo}

  @enforce_keys [:credentials]
  defstruct [:credentials, tokens: %{}]

  @refresh_strategy Application.compile_env(:auth0_ex, :refresh_strategy, ProbabilisticRefreshStrategy)
  @token_service Application.compile_env(:auth0_ex, :token_service, CachedTokenService)

  @token_check_interval Application.compile_env!(:auth0_ex, :client)[:token_check_interval]

  # Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:credentials], opts)
  end

  @spec token_for(GenServer.server(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def token_for(pid, target_audience) do
    GenServer.call(pid, {:token_for, target_audience})
  end

  # Callbacks

  @impl true
  def init(auth0_credentials) do
    {:ok, %__MODULE__{credentials: auth0_credentials}}
  end

  @impl true
  def handle_call({:token_for, audience}, _from, state) do
    case state.tokens[audience] do
      nil ->
        case initialize_token_for(audience, state) do
          {:ok, %TokenInfo{} = token} ->
            {:reply, {:ok, token.jwt}, set_token(state, audience, token)}

          {:error, reason} ->
            Logger.error("Error initializing token.", audience: audience, reason: inspect(reason))
            {:reply, {:error, reason}, state}
        end

      %TokenInfo{jwt: jwt} ->
        {:reply, {:ok, jwt}, state}
    end
  end

  @impl true
  def handle_info({:periodic_check_for, audience}, state) do
    Logger.debug("Running periodic check...", audience: audience)
    token = state.tokens[audience]

    if @refresh_strategy.should_refresh?(token) do
      Logger.info("Decided to refresh token.",
        audience: audience,
        current_token_issued_at: token.issued_at,
        current_token_expires_at: token.expires_at
      )

      self_pid = self()

      spawn(fn ->
        {:ok, new_token} = @token_service.refresh_token(state.credentials, audience, token)
        send(self_pid, {:set_token_for, audience, new_token})
      end)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:set_token_for, audience, token}, state) do
    {:noreply, set_token(state, audience, token)}
  end

  defp initialize_token_for(audience, state) do
    Logger.info("Initializing token", audience: audience)

    with {:ok, token} <- @token_service.retrieve_token(state.credentials, audience),
         {:ok, _} <- :timer.send_interval(@token_check_interval, {:periodic_check_for, audience}),
         do: {:ok, token}
  end

  defp set_token(state, audience, token), do: put_in(state.tokens[audience], token)
end
