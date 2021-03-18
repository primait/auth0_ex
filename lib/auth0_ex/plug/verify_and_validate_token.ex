defmodule Auth0Ex.Plug.VerifyAndValidateToken do
  @moduledoc """
  Plug to verify and validate bearer tokens

  Usage:

    plug Auth0Ex.Plug.VerifyAndValidateToken, required_permissions: ["some:permission"]

  ## Options

  The following options can be set to customize the behavior of this plug:

  * `audience: "my-audience"` sets the expected audience. Defaults to the audience set in `config.exs`.
  * `required_permissions: ["p1", "p2"]` sets the sets of permissions that clients are required to have.
    Clients who do not have **all** the required permissions are forbidden from accessing the API.
    Defaults to `[]`, ie. no permissions required.
  * `dry_run: true` when true allows clients to access the API even when their token is missing/invalid.
    Mostly useful for testing purposes.
  """

  import Plug.Conn
  require Logger

  @global_audience Application.compile_env!(:auth0_ex, :server)[:audience]
  @global_dry_run :auth0_ex |> Application.compile_env!(:server) |> Keyword.get(:dry_run, false)

  def init(opts), do: opts

  def call(%Plug.Conn{} = conn, opts) do
    audience = Keyword.get(opts, :audience, @global_audience)
    dry_run? = Keyword.get(opts, :dry_run, @global_dry_run)
    required_permissions = Keyword.get(opts, :required_permissions, [])

    if authorized?(conn, audience, required_permissions), do: conn, else: forbidden(conn, dry_run?)
  end

  defp authorized?(conn, audience, required_permissions) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        valid_token?(token, audience, required_permissions)

      _other ->
        Logger.warn("Authorization header malformed or not found")
        false
    end
  end

  defp valid_token?(token, audience, required_permissions) do
    case Auth0Ex.verify_and_validate(token, audience, required_permissions) do
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
end
