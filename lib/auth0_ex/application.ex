defmodule Auth0Ex.Application do
  use Application

  alias Auth0Ex.TokenProvider

  def start(_type, _args) do
    children = [
      {TokenProvider, credentials: Auth0Ex.Auth0Credentials.from_env(), name: TokenProvider},
      {Redix, name: :redix}
    ]

    opts = [strategy: :one_for_one, name: Auth0Ex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
