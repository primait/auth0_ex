defmodule Auth0Ex.Consumer do
  @behaviour GenServer

  @enforce_keys [:credentials]
  defstruct [:credentials, tokens: %{}]

  @authorization_service Application.compile_env!(:auth0_ex, :authorization_service)
  @refresh_strategy Application.compile_env!(:auth0_ex, :refresh_strategy)
  @token_cache Application.compile_env!(:auth0_ex, :token_cache)
  @token_check_interval Application.compile_env!(:auth0_ex, :token_check_interval)

  # Client

  def start_link(initial_state) when is_struct(initial_state, __MODULE__) do
    GenServer.start_link(__MODULE__, initial_state)
  end

  def token_for(pid, target_audience) do
    GenServer.call(pid, {:token_for, target_audience})
  end

  # Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:token_for, audience}, _from, state) do
    case state.tokens[audience] do
      nil ->
        token = initialize_token_for(audience, state)
        {:reply, token, set_token(state, audience, token)}

      token ->
        {:reply, token, state}
    end
  end

  @impl true
  def handle_info({:periodic_check_for, audience}, state) do
    token = state.tokens[audience]

    if @refresh_strategy.should_refresh?(token) do
      self_pid = self()

      spawn(fn ->
        {:ok, new_token} = refresh_token_for(audience, state.credentials, token)
        GenServer.cast(self_pid, {:set_token_for, audience, new_token})
      end)
    end

    schedule_periodic_check_for(audience)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:set_token_for, audience, token}, state) do
    {:noreply, set_token(state, audience, token)}
  end

  defp initialize_token_for(audience, state) do
    schedule_periodic_check_for(audience)

    {:ok, token} = refresh_token_for(audience, state.credentials)
    token
  end

  defp refresh_token_for(audience, credentials, current_token \\ nil) do
    token_from_cache =
      case @token_cache.get_token_for(audience) do
        {:error, :not_found} -> nil
        {:ok, token} -> token
      end

    token =
      if token_from_cache == current_token or !token_from_cache do
        {:ok, token} = @authorization_service.retrieve_token(credentials, audience)
        @token_cache.set_token_for(audience, token)

        token
      else
        token_from_cache
      end

    {:ok, token}
  end

  defp schedule_periodic_check_for(audience) do
    Process.send_after(self(), {:periodic_check_for, audience}, @token_check_interval)
  end

  defp set_token(state, audience, token) do
    put_in(state.tokens[audience], token)
  end
end
