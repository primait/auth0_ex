defmodule Auth0Ex.Consumer do
  @behaviour GenServer

  @enforce_keys [:base_url, :client_id, :client_secret]
  defstruct [:base_url, :client_id, :client_secret, tokens: %{}]

  @authorization_service Application.compile_env!(:auth0_ex, :authorization_service)

  # Client

  def token_for(pid, target_audience) do
    GenServer.call(pid, {:token_for, target_audience})
  end

  # Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  def start_link(initial_state) when is_struct(initial_state, __MODULE__) do
    GenServer.start_link(__MODULE__, initial_state)
  end

  @impl true
  def handle_call({:token_for, audience}, _from, state) do
    token = state.tokens[audience]

    if valid?(token) do
      {:reply, token, state}
    else
      {:ok, token} =
        @authorization_service.retrieve_token(
          state.base_url,
          state.client_id,
          state.client_secret,
          audience
        )

      state = put_in(state.tokens[audience], token)
      {:reply, token, state}
    end
  end

  defp valid?(nil), do: false

  defp valid?(token) do
    minimum_remaining_time = 10 * 60
    {:ok, claims} = Joken.peek_claims(token)

    claims["exp"] > Joken.current_time() + minimum_remaining_time
  end
end
