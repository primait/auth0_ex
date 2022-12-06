if Code.ensure_loaded?(Plug) do
  defmodule PrimaAuth0Ex.Plug.VerifyAndValidateToken do
    @moduledoc """
    Plug to verify and validate bearer tokens

    Usage:

    ```
    plug PrimaAuth0Ex.Plug.VerifyAndValidateToken, required_permissions: ["some:permission"]
    ```

    ## Options

    The following options can be set to customize the behavior of this plug:

    * `required_permissions: ["p1", "p2"]` **(mandatory)**: sets the permissions that clients are required to have.
      Clients who do not have **all** the required permissions are forbidden from accessing the API.
      If you don't want to require any permissions, you can pass an empty list (`[]`) to this option.
    * `audience: "my-audience"`: sets the expected audience. Defaults to the audience set in `config.exs`.
    * `dry_run: false`: when true allows clients to access the API even when their token is missing/invalid.
      Mostly useful for testing purposes. Default is `false`, overridable from `config.exs`.
    * `ignore_signature: false`: when true, validates claims found in a token without verifying its signature.
      Should only be enabled in dev/test environments, as it allows anyone to forge valid tokens.
      Default is `false`, overridable from `config.exs`.
    """

    import Plug.Conn

    require Logger

    def init(opts) do
      if !Keyword.has_key?(opts, :required_permissions) do
        raise "required_permissions configuration must be set"
      end

      opts
    end

    def call(%Plug.Conn{} = conn, opts) do
      audience = Keyword.get(opts, :audience, global_audience())
      dry_run? = Keyword.get(opts, :dry_run, global_dry_run())
      ignore_signature = Keyword.get(opts, :ignore_signature, global_ignore_signature())
      required_permissions = Keyword.get(opts, :required_permissions)

      missing_auth_header_log_level =
        Keyword.get(opts, :missing_auth_header_log_level, global_missing_auth_header_log_level())

      if authorized?(conn, audience, required_permissions, ignore_signature, missing_auth_header_log_level),
        do: conn,
        else: forbidden(conn, dry_run?)
    end

    defp authorized?(conn, audience, required_permissions, ignore_signature, missing_auth_header_log_level) do
      case get_req_header(conn, "authorization") do
        [] ->
          Logger.log(missing_auth_header_log_level, "Authorization header not found")
          false

        ["Bearer " <> token] ->
          valid_token?(token, audience, required_permissions, ignore_signature)

        _other ->
          Logger.warn("Authorization header malformed")
          false
      end
    end

    defp valid_token?(token, audience, required_permissions, ignore_signature) do
      case PrimaAuth0Ex.verify_and_validate(token, audience, required_permissions, ignore_signature) do
        {:ok, _} ->
          true

        {:error, error} ->
          Logger.warn("Received invalid token",
            audience: audience,
            required_permissions: required_permissions,
            error: inspect(error)
          )

          false
      end
    end

    defp forbidden(conn, true = _dry_run?), do: conn

    defp forbidden(conn, false = _dry_run?) do
      conn
      |> send_resp(:unauthorized, "Forbidden.")
      |> halt()
    end

    defp global_audience,
      do: :prima_auth0_ex |> Application.get_env(:server, []) |> Keyword.get(:audience)

    defp global_dry_run,
      do: :prima_auth0_ex |> Application.get_env(:server, []) |> Keyword.get(:dry_run, false)

    defp global_ignore_signature,
      do:
        :prima_auth0_ex
        |> Application.get_env(:server, [])
        |> Keyword.get(:ignore_signature, false)

    defp global_missing_auth_header_log_level,
      do:
        :prima_auth0_ex
        |> Application.get_env(:server, [])
        |> Keyword.get(:missing_auth_header_log_level, :warn)
  end
end
