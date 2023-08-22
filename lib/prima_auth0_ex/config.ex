defmodule PrimaAuth0Ex.Config do
  def clients, do: get_env(:clients)
  def clients(client), do: :clients |> get_env() |> Keyword.get(client, [])

  def clients(client, prop, default),
    do: :clients |> get_env() |> Keyword.get(client, []) |> Keyword.get(prop, default)

  def default_client(prop \\ nil, default \\ nil), do: get_env(:client, prop, default)

  def jwks_kids_fetcher(default),
    do: get_env(:jwks_kids_fetcher, default)

  def redis(prop \\ nil, default \\ nil), do: get_env(:redis, prop, default)

  def refresh_strategy(default),
    do: get_env(:refresh_strategy, default)

  def server(prop \\ nil, default \\ nil), do: get_env(:server, prop, default)
  def server!(prop), do: fetch_env!(:server, prop)
  def telemetry_reporter, do: get_env(:telemetry_reporter)

  def token_service(default), do: get_env(:token_service, default)

  # Base methods

  defp fetch_env!(conf, prop), do: :prima_auth0_ex |> Application.fetch_env!(conf) |> Keyword.fetch!(prop)

  defp get_env(conf, default \\ []), do: Application.get_env(:prima_auth0_ex, conf, default)

  defp get_env(conf, prop, default),
    do: :prima_auth0_ex |> Application.get_env(conf, []) |> Keyword.get(prop, default)
end
