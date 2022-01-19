defmodule PrimaAuth0Ex.Application do
  @moduledoc false

  use Application

  require Logger

  alias PrimaAuth0Ex.{JwksStrategy, TokenProvider}

  def start(_type, _args) do
    log_configuration_errors()

    children = client_children() ++ cache_children() ++ server_children()
    opts = [strategy: :one_for_one, name: PrimaAuth0Ex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp client_children do
    if client_configured?() do
      [{TokenProvider, credentials: PrimaAuth0Ex.Auth0Credentials.from_env(), name: TokenProvider}]
    else
      []
    end
  end

  defp cache_children do
    if cache_enabled?() do
      [{Redix, {redis_connection_uri(), [name: PrimaAuth0Ex.Redix]}}]
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

  defp cache_enabled?, do: Application.get_env(:prima_auth0_ex, :client, cache_enabled: false)[:cache_enabled]
  defp client_configured?, do: Application.get_env(:prima_auth0_ex, :client) != nil
  defp server_configured?, do: Application.get_env(:prima_auth0_ex, :server) != nil

  defp server_signature_ignored?,
    do: :prima_auth0_ex |> Application.get_env(:server, []) |> Keyword.get(:ignore_signature, false)

  defp redis_connection_uri, do: Application.fetch_env!(:prima_auth0_ex, :client)[:redis_connection_uri]

  defp first_jwks_fetch_sync do
    :prima_auth0_ex |> Application.get_env(:server, []) |> Keyword.get(:first_jwks_fetch_sync, false)
  end

  defp log_configuration_errors do
    unless Application.get_env(:prima_auth0_ex, :auth0_base_url) do
      Logger.warning("Missing required configuration 'auth0_base_url'")
    end

    unless client_configured?() or server_configured?() do
      Logger.warning("No configuration found neither for client nor for server")
    end
  end
end
