defmodule PrimaAuth0Ex.TokenCache do
  @moduledoc """
  Behaviour that defines a cache for tokens.
  """
  alias PrimaAuth0Ex.Config
  alias PrimaAuth0Ex.TokenProvider.TokenInfo

  @callback set_token_for(atom(), String.t(), TokenInfo.t()) :: :ok | {:error, any()}
  @callback get_token_for(atom(), String.t()) :: {:ok, TokenInfo.t() | nil} | {:error, any()}
  @callback child_spec(any()) :: Supervisor.child_spec()

  def set_token_for(client, audience, token) do
    get_configured_cache_provider().set_token_for(client, audience, token)
  end

  def get_token_for(client, audience) do
    get_configured_cache_provider().get_token_for(client, audience)
  end

  def child_spec(opts) do
    get_configured_cache_provider().child_spec(opts)
  end

  def get_configured_cache_provider do
    cache_provider = Config.token_cache(MemoryCache)

    with builtin_cache_provider <- Module.concat(PrimaAuth0Ex.TokenCache, cache_provider),
         {:module, ^builtin_cache_provider} <- Code.ensure_compiled(builtin_cache_provider) do
      builtin_cache_provider
    else
      _ -> cache_provider
    end
  end
end
