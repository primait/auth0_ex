defmodule PrimaAuth0Ex.Config do
  def clients, do: get_env(:clients)
  def clients(client), do: :clients |> get_env() |> Keyword.get(client, [])

  def clients(client, prop, default),
    do: :clients |> get_env() |> Keyword.get(client, []) |> Keyword.get(prop, default)

  def default_client(prop \\ nil, default \\ nil), do: get_env(:client, prop, default)
  def redis(prop \\ nil, default \\ nil), do: get_env(:redis, prop, default)
  def server(prop \\ nil, default \\ nil), do: get_env(:server, prop, default)

  defp get_env(conf), do: Application.get_env(:prima_auth0_ex, conf, [])

  defp get_env(conf, prop, default),
    do: :prima_auth0_ex |> Application.get_env(conf, []) |> Keyword.get(prop, default)
end
