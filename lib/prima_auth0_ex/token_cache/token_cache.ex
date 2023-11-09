defmodule PrimaAuth0Ex.TokenCache do
  @moduledoc """
  Behaviour that defines a cache for tokens.
  """
  alias PrimaAuth0Ex.Config
  alias PrimaAuth0Ex.TokenProvider.TokenInfo

  @callback set_token_for(atom(), String.t(), TokenInfo.t()) :: :ok | {:error, any()}
  @callback get_token_for(atom(), String.t()) :: {:ok, TokenInfo.t() | nil} | {:error, any()}

  def start_link(opts), do: get_configured_cache_provider().start_link(opts) 
  def children, do: get_configured_cache_provider().children()

  def set_token_for(client, audience, token) do
    get_configured_cache_provider().set_token_for(client, audience, token)
  end

  def get_token_for(client, audience) do
    get_configured_cache_provider().get_token_for(client, audience)
  end

  defp get_configured_cache_provider do
    case Config.cache(:provider, :none) do
      :redis ->
        PrimaAuth0Ex.TokenCache.EncryptedRedisTokenCache
      :none ->
        PrimaAuth0Ex.TokenCache.NoopCache
    end
  end
end
