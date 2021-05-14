defmodule Auth0Ex.Application do
  @moduledoc false

  use Application

  alias Auth0Ex.{JwksStrategy, TokenProvider}

  def start(_type, _args) do
    children = client_children() ++ cache_children() ++ server_children()

    opts = [strategy: :one_for_one, name: Auth0Ex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp client_children do
    if client_configured?() do
      [{TokenProvider, credentials: Auth0Ex.Auth0Credentials.from_env(), name: TokenProvider}]
    else
      []
    end
  end

  defp cache_children do
    if cache_enabled?() do
      [{Redix, {redis_connection_uri(), [name: Auth0Ex.Redix]}}]
    else
      []
    end
  end

  defp server_children do
    if server_configured?() && not server_signature_ignored?() do
      [{JwksStrategy, [first_fetch_sync: first_jwks_fetch_sync()]}]
    else
      []
    end
  end

  defp cache_enabled?, do: Application.get_env(:auth0_ex, :client, cache_enabled: false)[:cache_enabled]
  defp client_configured?, do: Application.get_env(:auth0_ex, :client) != nil
  defp server_configured?, do: Application.get_env(:auth0_ex, :server) != nil

  defp server_signature_ignored?,
    do: :auth0_ex |> Application.get_env(:server, []) |> Keyword.get(:ignore_signature, false)

  defp redis_connection_uri, do: Application.fetch_env!(:auth0_ex, :client)[:redis_connection_uri]

  defp first_jwks_fetch_sync do
    :auth0_ex |> Application.get_env(:server, []) |> Keyword.get(:first_jwks_fetch_sync, false)
  end
end
