defmodule PrimaAuth0Ex.Config do
  @moduledoc "Configuration wrapper"

  def authorization_service(default),
    do: get_env(:authorization_service, default)

  def cache(prop, default \\ nil), do: get_env(:cache, prop, default)
  def cache!(prop), do: fetch_env!(:cache, prop)

  def clients, do: get_env(:clients, nil)
  def clients(client_id), do: :clients |> get_env([]) |> Keyword.get(client_id)

  def clients(client_id, prop, default),
    do: client_id |> clients() |> Keyword.get(prop, default)

  def clients!(client, prop),
    do: :clients |> fetch_env!(client) |> Keyword.fetch!(prop)

  def default_client, do: clients(:default_client)
  def default_client(prop, default \\ nil), do: clients(:default_client, prop, default)
  def default_client!(prop), do: clients!(:default_client, prop)

  def jwks_kids_fetcher(default),
    do: get_env(:jwks_kids_fetcher, default)

  def redis(prop, default \\ nil), do: get_env(:redis, prop, default)
  def redis!(prop), do: fetch_env!(:redis, prop)

  def refresh_strategy(default),
    do: get_env(:refresh_strategy, default)

  def server, do: get_env(:server, nil)
  def server(prop, default \\ nil), do: get_env(:server, prop, default)
  def server!(prop), do: fetch_env!(:server, prop)
  def telemetry_reporter, do: get_env(:telemetry_reporter, nil)

  @doc """
  Module to use for caching tokens.
  Needs to implement the PrimaAuth0Ex.TokenCache behavior.
  Modules with the PrimaAuth0Ex.TokenCache prefix(PrimaAuth0Ex.TokenCache.EncryptedRedisTokenCache, PrimaAuth0Ex.TokenCache.NoopCache) can be used without the prefix(just EncryptedRedisTokenCache and NoopCache)
  """
  def token_cache(default), do: get_env(:token_cache, default)

  def token_service(default), do: get_env(:token_service, default)

  # Base methods

  defp fetch_env!(conf, prop),
    do: :prima_auth0_ex |> Application.fetch_env!(conf) |> Keyword.fetch!(prop)

  defp get_env(conf, default), do: Application.get_env(:prima_auth0_ex, conf, default)

  defp get_env(conf, prop, default),
    do: :prima_auth0_ex |> Application.get_env(conf, []) |> Keyword.get(prop, default)
end
