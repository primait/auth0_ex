defmodule Auth0Ex.Plug.VerifyAndValidateToken do
  import Plug.Conn

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
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp forbidden(conn) do
    conn
    |> send_resp(:unauthorized, "Forbidden.")
    |> halt()
  end
end
