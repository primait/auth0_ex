defmodule PrimaAuth0Ex.Application do
  @moduledoc false

  use Application

  require Logger

  alias PrimaAuth0Ex.Config
  alias PrimaAuth0Ex.Telemetry
  alias PrimaAuth0Ex.TokenCache.EncryptedRedisTokenCache
  alias PrimaAuth0Ex.{JwksStrategy, TokenProvider}
  alias PrimaAuth0Ex.TokenCache.NoopCache

  def start(_type, _args) do
    unless Config.default_client() || Config.clients() || Config.server() do
      Logger.warning("No configuration found neither for client(s) nor for server")
    end

    if Config.server() do
      validate_server_config()
    end

    migrate_deprecated_cache_options()

    Telemetry.setup()

    children = client_children() ++ cache_children() ++ server_children()
    opts = [strategy: :one_for_one, name: PrimaAuth0Ex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp migrate_deprecated_cache_options do
    redis_enabled = Config.redis(:enabled)
    cache_provider = Config.token_cache(nil)

    case {redis_enabled, cache_provider} do
      {nil, _} ->
        nil

      {true, nil} ->
        Application.put_env(:prima_auth0_ex, :token_cache, EncryptedRedisTokenCache)

        Logger.warning("""
        The
          :prima_auth0_ex, :redis, :enabled option
        is deprecated.
        Set
          :prima_auth0_ex, token_cache: EncryptedRedisTokenCache
        instead
        """)

      {true, _} ->
        Logger.warning("""
        The
          :prima_auth0_ex, :redis, :enabled option
        is deprecated.
        Setting
          :prima_auth0_ex, token_cache: #{cache_provider}
        alone is sufficient
        """)

      {false, nil} ->
        Application.put_env(:prima_auth0_ex, :token_cache, NoopCache)

        Logger.warning("""
        The :prima_auth0_ex, :redis, :enabled option is deprecated.
        Set
          :prima_auth0_ex, token_cache: NoopCache
        instead to disable caching
        """)

      {false, _} ->
        Logger.warning("""
        The :prima_auth0_ex, :redis, :enabled option is deprecated. You can safely remove it
          :prima_auth0_ex, :token_cache,
        is used instead
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

  defp cache_children, do: [PrimaAuth0Ex.TokenCache]

  defp server_children do
    if Config.server() && not Config.server(:ignore_signature, false) do
      [{JwksStrategy, [first_fetch_sync: Config.server(:first_jwks_fetch_sync, true)]}]
    else
      []
    end
  end

  defp validate_server_config do
    if not is_binary(Config.server(:audience)) do
      raise """
      Server :audience needs to be a string, got #{Config.server(:audience)} instead.

      Suggestion:

        config :prima_auth0_ex, :server,
          ...
          audience: #{to_string(Config.server(:audience))},
          ...
      """
    end
  end
end
