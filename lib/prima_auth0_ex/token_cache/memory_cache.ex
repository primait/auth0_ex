defmodule PrimaAuth0Ex.TokenCache.MemoryCache do
  # Use a genserver for the implementation.
  # We could use ets instead, to allow multiple readers at once
  # but that wouldn't allow cache access from other nodes.
  use GenServer

  alias PrimaAuth0Ex.Config
  alias PrimaAuth0Ex.TokenCache
  alias PrimaAuth0Ex.TokenProvider.TokenInfo

  @moduledoc """
  Implementation of `PrimaAuth0Ex.TokenCache` that stores tokens in memory.
  The cache is shared between nodes.
  """

  @behaviour TokenCache
  @impl TokenCache
  def get_token_for(client, audience) do
    GenServer.call(__MODULE__, {:get_token_for, client, audience})
  end

  @impl TokenCache
  def set_token_for(client, audience, token) do
    GenServer.cast(__MODULE__, {:set_token_for, client, audience, token})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    schedule_cleanup()
    {:ok, Map.new()}
  end

  @impl true
  def handle_call({:get_token_for, client, audience}, _from, tokens) do
    resp = do_get_token_for(client, audience, tokens)
    {:reply, resp, tokens}
  end

  defp do_get_token_for(client, audience, tokens) do
    current_time = now_unix()

    case Map.get(tokens, {client, audience}) do
      %TokenInfo{expires_at: expires_at} = token when expires_at > current_time ->
        {:ok, token}

      # Token expired or not cached
      _ ->
        {:ok, nil}
    end
  end

  @impl true
  def handle_cast({:set_token_for, client, audience, token}, tokens) do
    tokens = Map.put(tokens, {client, audience}, token)
    {:noreply, tokens}
  end

  @impl true
  def handle_info(:cleanup, tokens) do
    tokens =
      Map.filter(tokens, fn {_, %TokenInfo{expires_at: expires_at}} ->
        expires_at > now_unix()
      end)

    schedule_cleanup()
    {:noreply, tokens}
  end

  defp now_unix, do: :os.system_time(:seconds)
  defp schedule_cleanup, do: Process.send_after(self(), :cleanup, cleanup_interval())

  @default_cleanup_interval_ms 60 * 1000
  defp cleanup_interval, do: Config.memory_cache(:cleanup_interval, @default_cleanup_interval_ms)
end
