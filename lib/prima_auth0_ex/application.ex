defmodule PrimaAuth0Ex.Application do
  @moduledoc false

  use Application

  require Logger

  alias PrimaAuth0Ex.Telemetry
  alias PrimaAuth0Ex.{JwksStrategy, TokenProvider}

  def start(_type, _args) do
    log_configuration_errors()
    Telemetry.setup()

    children = client_children() ++ cache_children() ++ server_children()
    opts = [strategy: :one_for_one, name: PrimaAuth0Ex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp client_children do
    if client_configured?() do
      Application.get_env(:prima_auth0_ex, :clients, %{})
      |> Map.keys()
      |> Enum.map(fn key ->
        {TokenProvider, credentials: PrimaAuth0Ex.Auth0Credentials.from_env(key), name: key}
      end)
    else
      []
    end
  end

  defp cache_children do
    if cache_enabled?() do
      Application.get_env(:prima_auth0_ex, :clients, %{})
      |> Map.keys()
      |> Enum.map(fn key ->
        {Redix, {redis_connection_uri(key), [name: PrimaAuth0Ex.Redix] ++ redis_ssl_opts(key)}}
      end)
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

  defp cache_enabled?,
    do: Application.get_env(:prima_auth0_ex, :client, cache_enabled: false)[:cache_enabled]

  defp client_configured?, do: Application.get_env(:prima_auth0_ex, :clients) != nil
  defp server_configured?, do: Application.get_env(:prima_auth0_ex, :server) != nil

  defp server_signature_ignored?,
    do: :prima_auth0_ex |> Application.get_env(:server, []) |> Keyword.get(:ignore_signature, false)

  defp redis_connection_uri(client_name),
    do:
      Application.fetch_env!(:prima_auth0_ex, :clients)
      |> Map.get(client_name)
      |> Keyword.get(:redis_connection_uri)

  def redis_ssl_opts(client_name) do
    if redis_ssl_enabled?(client_name) do
      append_if([ssl: true], redis_ssl_allow_wildcard_certificates?(client_name),
        socket_opts: [
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      )
    else
      []
    end
  end

  defp redis_ssl_enabled?(client_name), do: get_redis_option(client_name, :redis_ssl_enabled)

  defp redis_ssl_allow_wildcard_certificates?(client_name),
    do: get_redis_option(client_name, :redis_ssl_allow_wildcard_certificates)

  defp get_redis_option(client_name, option) do
    Application.get_env(:prima_auth0_ex, :clients, %{})
    |> Map.get(client_name)
    |> Keyword.get(option) || false
  end

  defp first_jwks_fetch_sync do
    :prima_auth0_ex
    |> Application.get_env(:server, [])
    |> Keyword.get(:first_jwks_fetch_sync, false)
  end

  defp log_configuration_errors do
    unless Application.get_env(:prima_auth0_ex, :auth0_base_url) do
      Logger.warning("Missing required configuration 'auth0_base_url'")
    end

    unless client_configured?() or server_configured?() do
      Logger.warning("No configuration found neither for client nor for server")
    end
  end

  defp append_if(list, false, _value), do: list
  defp append_if(list, true, value), do: list ++ value
end
