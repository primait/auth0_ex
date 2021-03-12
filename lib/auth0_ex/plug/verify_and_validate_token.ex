defmodule Auth0Ex.Plug.VerifyAndValidateToken do
  @moduledoc """
  Plug to verify and validate bearer tokens

  ## Usage

  When no parameter is set, validates tokens for the audience set in config.

    plug Auth0Ex.Plug.VerifyAndValidateToken

  To define a custom audience for token validation:

    plug Auth0Ex.Plug.VerifyAndValidateToken, audience: "my-audience"

  A set of required permissions can be set as follows:

    plug Auth0Ex.Plug.VerifyAndValidateToken, requried_permissions: ["some", "permissions"]

  When permissions are required, only requests from users with *all* the required permissions are processed.
  """

  import Plug.Conn
  require Logger

  def init(options), do: options

  def call(%Plug.Conn{} = conn, opts) do
    audience = opts[:audience]
    required_permissions = opts[:required_permissions] || []

    case authorized?(conn, audience, required_permissions) do
      true -> conn
      false -> forbidden(conn)
    end
  end

  defp authorized?(conn, audience, required_permissions) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> valid_token?(token, audience, required_permissions)
      _other -> false
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

  defp forbidden(conn) do
    conn
    |> send_resp(:unauthorized, "Forbidden.")
    |> halt()
  end
end
