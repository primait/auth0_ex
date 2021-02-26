defmodule Auth0Ex.Consumer do
  @behaviour GenServer

  @enforce_keys [:credentials]
  defstruct [:credentials, tokens: %{}]

  @authorization_service Application.compile_env!(:auth0_ex, :authorization_service)
  @token_cache Application.compile_env!(:auth0_ex, :token_cache)

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
    case @token_cache.get_token_for(audience) do
      {:ok, token} ->
        new_state = put_in(state.tokens[audience], token)
        {:reply, token, new_state}

      {:error, :not_found} ->
        {:ok, token} =
          @authorization_service.retrieve_token(
            state.credentials,
            audience
          )

        state = put_in(state.tokens[audience], token)
        @token_cache.set_token_for(audience, token)
        {:reply, token, state}
    end
  end
end
