defmodule Auth0Ex.Application do
  @moduledoc false

  use Application

  alias Auth0Ex.{JwksStrategy, TokenProvider}

  def start(_type, _args) do
    children = if client_enabled?(), do: client_children(), else: []
    children = if server_enabled?(), do: children ++ server_children(), else: children

    opts = [strategy: :one_for_one, name: Auth0Ex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp client_enabled?, do: Application.get_env(:auth0_ex, :client) != nil
  defp server_enabled?, do: Application.get_env(:auth0_ex, :server) != nil

  defp client_children do
    [
      {Redix, {redis_connection_uri(), [name: Auth0Ex.Redix]}},
      {TokenProvider, credentials: Auth0Ex.Auth0Credentials.from_env(), name: TokenProvider}
    ]
  end

  defp server_children do
    [
      {JwksStrategy, [first_fetch_sync: first_jwks_fetch_sync()]}
    ]
  end

  defp redis_connection_uri, do: Application.fetch_env!(:auth0_ex, :cache)[:redis_connection_uri]

  defp first_jwks_fetch_sync do
    Keyword.get(Application.get_env(:auth0_ex, :server, []), :first_jwks_fetch_sync, false)
  end
end
