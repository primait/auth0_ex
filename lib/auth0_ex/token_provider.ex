defmodule Auth0Ex.TokenProvider do
  @moduledoc """
  GenServer that handles the storage and refresh of tokens.

  Every time a token for a new audience is requested, it retrieves it either from a cache (when possible)
  or from an authorization provider.
  Then, it runs periodic checks to ensure that all tokens are still valid, and it refreshes them when necessary.
  """

  use GenServer

  require Logger
  alias Auth0Ex.TokenProvider.{Auth0TokenVerifier, CachedTokenService, ProbabilisticRefreshStrategy, TokenInfo}

  @type t() :: %__MODULE__{
          credentials: Auth0Ex.Auth0Credentials,
          tokens: %{required(String.t()) => TokenInfo.t()},
          refresh_times: %{required(String.t()) => Timex.Types.valid_datetime()}
        }
  @enforce_keys [:credentials]
  defstruct [:credentials, tokens: %{}, refresh_times: %{}]

  @refresh_strategy Application.compile_env(:auth0_ex, :refresh_strategy, ProbabilisticRefreshStrategy)
  @token_service Application.compile_env(:auth0_ex, :token_service, CachedTokenService)
  @token_verifier Application.compile_env(:auth0_ex, :token_verifier, Auth0TokenVerifier)

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
    with {:ok, _} <- :timer.send_interval(token_check_interval(), :periodic_check),
         :ok <- start_periodic_signature_check() do
      {:ok, %__MODULE__{credentials: auth0_credentials}}
    else
      error -> {:stop, error}
    end
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
  def handle_info(:periodic_check, state) do
    Logger.debug("Running periodic check...")

    parent = self()

    spawn(fn ->
      check_expiration_dates(state, parent)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info(:periodic_signature_check, state) do
    Logger.debug("Checking signatures...")

    parent = self()

    spawn(fn ->
      check_signatures(state, parent)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:set_token_for, audience, token}, state) do
    {:noreply, set_token(state, audience, token)}
  end

  defp check_expiration_dates(state, parent) do
    for {audience, _token} <- state.tokens do
      token = state.tokens[audience]

      if should_refresh?(audience, state) do
        Logger.info("Decided to refresh token.",
          audience: audience,
          token_issued_at: token.issued_at,
          token_expires_at: token.expires_at
        )

        try_refresh(audience, token, state.credentials, parent)
      end
    end
  end

  defp check_signatures(state, _parent) when state.tokens == %{}, do: nil

  defp check_signatures(state, parent) do
    @token_verifier.fetch_jwks()

    for {audience, token} <- state.tokens do
      unless @token_verifier.signature_valid?(token) do
        Logger.info("Refreshing token due to invalid signature.")

        try_refresh(audience, token, state.credentials, parent)
      end
    end
  end

  defp initialize_token_for(audience, state) do
    Logger.info("Initializing token", audience: audience)

    with {:ok, token} <- @token_service.retrieve_token(state.credentials, audience),
         do: {:ok, token}
  end

  defp set_token(state, audience, token) do
    refresh_time = @refresh_strategy.refresh_time_for(token)

    state
    |> put_in([Access.key(:tokens), audience], token)
    |> put_in([Access.key(:refresh_times), audience], refresh_time)
  end

  defp should_refresh?(audience, state) do
    state.refresh_times
    |> Map.get(audience)
    |> Timex.before?(Timex.now())
  end

  defp token_check_interval do
    :auth0_ex |> Application.get_env(:client, []) |> Keyword.get(:token_check_interval, :timer.minutes(1))
  end

  defp signature_check_interval do
    :auth0_ex |> Application.get_env(:client, []) |> Keyword.get(:signature_check_interval, :timer.minutes(5))
  end

  defp try_refresh(audience, token, credentials, parent) do
    case @token_service.refresh_token(credentials, audience, token) do
      {:ok, new_token} -> send(parent, {:set_token_for, audience, new_token})
      {:error, description} -> Logger.warn("Error refreshing token", audience: audience, description: description)
    end
  end

  defp start_periodic_signature_check do
    if client_signature_ignored?(), do: :ok, else: do_start_periodic_signature_check()
  end

  defp do_start_periodic_signature_check do
    case :timer.send_interval(signature_check_interval(), :periodic_signature_check) do
      {:ok, _} -> :ok
      error -> {:error, error}
    end
  end

  defp client_signature_ignored?,
    do: :auth0_ex |> Application.get_env(:client, []) |> Keyword.get(:ignore_signature, false)
end
