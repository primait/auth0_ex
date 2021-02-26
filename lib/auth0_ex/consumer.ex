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
    case state.tokens[audience] do
      nil ->
        token = retrieve_token_for(audience, state)
        {:reply, token, set_token(state, audience, token)}

      token ->
        {:reply, token, state}
    end
  end

  defp retrieve_token_for(audience, state) do
    case @token_cache.get_token_for(audience) do
      {:ok, token} ->
        token

      {:error, :not_found} ->
        {:ok, token} =
          @authorization_service.retrieve_token(
            state.credentials,
            audience
          )

        @token_cache.set_token_for(audience, token)
        token
    end
  end

  defp set_token(state, audience, token) do
    put_in(state.tokens[audience], token)
  end
end
