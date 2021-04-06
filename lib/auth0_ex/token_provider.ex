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

  @type t() :: %__MODULE__{
          credentials: Auth0Ex.Auth0Credentials,
          tokens: %{required(String.t()) => TokenInfo.t()},
          refresh_times: %{required(String.t()) => Timex.Types.valid_datetime()}
        }
  @enforce_keys [:credentials]
  defstruct [:credentials, tokens: %{}, refresh_times: %{}]

  @refresh_strategy Application.compile_env(:auth0_ex, :refresh_strategy, ProbabilisticRefreshStrategy)
  @token_service Application.compile_env(:auth0_ex, :token_service, CachedTokenService)

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
          {:ok, %TokenInfo{jwt: jwt} = token} ->
            {:reply, {:ok, jwt}, set_token(state, audience, token)}

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

    if should_refresh?(audience, state) do
      Logger.info("Decided to refresh token.", audience: audience)

      try_refresh(audience, state)
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
         {:ok, _} <- :timer.send_interval(token_check_interval(), {:periodic_check_for, audience}),
         do: {:ok, token}
  end

  defp set_token(state, audience, token) do
    refresh_time = @refresh_strategy.refresh_time_for(token)

    state
    |> put_in([Access.key(:tokens), audience], token)
    |> put_in([Access.key(:refresh_times), audience], refresh_time)
  end

  defp should_refresh?(audience, state) do
    refresh_time = state.refresh_times[audience]

    Timex.before?(refresh_time, Timex.now())
  end

  defp token_check_interval do
    :auth0_ex |> Application.get_env(:client, []) |> Keyword.get(:token_check_interval, :timer.minutes(1))
  end

  defp try_refresh(audience, state) do
    token = state.tokens[audience]
    parent = self()

    spawn(fn ->
      {:ok, new_token} = @token_service.refresh_token(state.credentials, audience, token)
      send(parent, {:set_token_for, audience, new_token})
    end)
  end
end
