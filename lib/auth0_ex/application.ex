defmodule Auth0Ex.Application do
  use Application

  alias Auth0Ex.{JwksStrategy, TokenProvider}

  def start(_type, _args) do
    children = [
      {JwksStrategy, []},
      {Redix, {redis_connection_uri(), [name: :redix]}},
      {TokenProvider, credentials: Auth0Ex.Auth0Credentials.from_env(), name: TokenProvider}
    ]

    opts = [strategy: :one_for_one, name: Auth0Ex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp redis_connection_uri, do: Application.fetch_env!(:auth0_ex, :cache)[:redis_connection_uri]
end
