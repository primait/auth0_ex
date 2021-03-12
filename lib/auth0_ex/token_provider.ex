defmodule Auth0Ex.TokenProvider do
  @moduledoc """
  GenServer that handles the storage and refresh of tokens.

  Every time a token for a new audience is requested, it retrieves it either from a cache (when possible)
  or from an authorization provider.
  Then, it runs periodic checks to ensure that all tokens are still valid, and it refreshes them when necessary.
  """

  use GenServer

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

  @spec token_for(GenServer.server(), String.t()) :: String.t()
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
          {:ok, token} -> {:reply, {:ok, token}, set_token(state, audience, token)}
          {:error, reason} -> {:reply, {:error, reason}, state}
        end

      %TokenInfo{jwt: token} ->
        {:reply, {:ok, token}, state}
    end
  end

  @impl true
  def handle_info({:periodic_check_for, audience}, state) do
    token = state.tokens[audience]

    if @refresh_strategy.should_refresh?(token) do
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
    :timer.send_interval(@token_check_interval, {:periodic_check_for, audience})

    @token_service.retrieve_token(state.credentials, audience)
  end

  defp set_token(state, audience, token), do: put_in(state.tokens[audience], token)
end
