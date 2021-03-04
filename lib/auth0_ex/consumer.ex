defmodule Auth0Ex.Consumer do
  use GenServer

  @enforce_keys [:credentials]
  defstruct [:credentials, tokens: %{}]

  @refresh_strategy Application.compile_env!(:auth0_ex, :refresh_strategy)
  @token_service Application.compile_env!(:auth0_ex, :token_service)

  @token_check_interval Application.compile_env!(:auth0_ex, :token_check_interval)

  # Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:credentials], opts)
  end

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
        {:ok, new_token} = @token_service.refresh_token(state.credentials, audience, token)
        send(self_pid, {:set_token_for, audience, new_token})
      end)
    end

    schedule_periodic_check_for(audience)
    {:noreply, state}
  end

  @impl true
  def handle_info({:set_token_for, audience, token}, state) do
    {:noreply, set_token(state, audience, token)}
  end

  defp initialize_token_for(audience, state) do
    schedule_periodic_check_for(audience)

    {:ok, token} = @token_service.retrieve_token(state.credentials, audience)
    token
  end

  defp schedule_periodic_check_for(audience) do
    Process.send_after(self(), {:periodic_check_for, audience}, @token_check_interval)
  end

  defp set_token(state, audience, token), do: put_in(state.tokens[audience], token)
end
