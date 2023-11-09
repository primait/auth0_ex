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

    migrate_depracated_cache_options()

    Telemetry.setup()

    children = client_children() ++ cache_children() ++ server_children()
    opts = [strategy: :one_for_one, name: PrimaAuth0Ex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp migrate_depracated_cache_options() do
    redis_enabled = Config.redis(:enabled)
    cache_provieder = Config.cache(:provider)

    case {redis_enabled, cache_provieder} do
      {nil, _} ->
        nil

      {true, nil} ->
        Application.put_env(:prima_auth0_ex, :cache, provider: :redis)

        Logger.warning("""
        The 
          :prima_auth0_ex, :redis, :enabled option 
        is depracated.
        Set
          :prima_auth0_ex, :cache, provider: :redis
        instead
        """)

      {false, nil} ->
        Application.put_env(:prima_auth0_ex, :cache, provider: :none)

        Logger.warning("""
        The :prima_auth0_ex, :redis, :enabled option is depracated.
        Set
          :prima_auth0_ex, :cache, provider: :none
        or
          :prima_auth0_ex, :cache, provider: :ets
        instead
        """)

      _ ->
        raise """
        Both 
          :prima_auth0_ex, :cache, :provider
        and
          :prima_auth0_ex, :redis, :enabled
        are configured. 
        The :prima_auth0_ex, :redis, :enabled option is depracated, and should be removed.
        """
    end

    unless redis_enabled == nil do
      Logger.warning("""
      Configuration option :prima_auth0_ex, :redis, :enabled is depreacted. 
      Set :prima_auth0_ex, :cache, provider: :redis instead
      """)
    end
  end

  defp client_children do
    if Config.clients() do
      Config.clients()
      |> Keyword.keys()
      |> Enum.reduce([], fn client_name, acc ->
        [
          Supervisor.child_spec(
            {TokenProvider,
             credentials: PrimaAuth0Ex.Auth0Credentials.from_env(client_name), name: client_name},
            id: client_name
          )
          | acc
        ]
      end)
    else
      []
    end
  end

  defp cache_children, do: PrimaAuth0Ex.TokenCache.children()

  defp server_children do
    if Config.server() && not Config.server(:ignore_signature, false) do
      [{JwksStrategy, [first_fetch_sync: Config.server(:first_jwks_fetch_sync, false)]}]
    else
      []
    end
  end
end
