defmodule PrimaAuth0Ex.Application do
  @moduledoc false

  use Application

  require Logger

  alias PrimaAuth0Ex.Config
  alias PrimaAuth0Ex.Telemetry
  alias PrimaAuth0Ex.{JwksStrategy, TokenProvider}

  def start(_type, _args) do
    unless Config.default_client() || Config.clients() || Config.server() do
      Logger.warning("No configuration found neither for client(s) nor for server")
    end

    Telemetry.setup()

    children = client_children() ++ cache_children() ++ server_children()
    opts = [strategy: :one_for_one, name: PrimaAuth0Ex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp client_children do
    if Config.clients() do
      Config.clients()
      |> Keyword.keys()
      |> Enum.reduce([], fn client_name, acc ->
        [
          Supervisor.child_spec(
            {TokenProvider, credentials: PrimaAuth0Ex.Auth0Credentials.from_env(client_name), name: client_name},
            id: client_name
          )
          | acc
        ]
      end)
    else
      []
    end
  end

  defp cache_children do
    if Config.redis(:enabled, false) do
      [{Redix, {Config.redis!(:connection_uri), [name: PrimaAuth0Ex.Redix] ++ redis_ssl_opts()}}]
    else
      []
    end
  end

  defp server_children do
    if Config.server() && not Config.server(:ignore_signature, false) do
      [{JwksStrategy, [first_fetch_sync: Config.server(:first_jwks_fetch_sync, false)]}]
    else
      []
    end
  end

  def redis_ssl_opts do
    if Config.redis(:ssl_enabled, false) do
      append_if([ssl: true], Config.redis(:ssl_allow_wildcard_certificates, false),
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

  defp append_if(list, false, _value), do: list
  defp append_if(list, true, value), do: list ++ value
end
