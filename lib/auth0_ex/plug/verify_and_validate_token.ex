defmodule Auth0Ex.Plug.VerifyAndValidateToken do
  import Plug.Conn

  def init(options), do: options

  def call(%Plug.Conn{} = conn, _opts) do
    case authorized?(conn) do
      true -> conn
      false -> forbidden(conn)
    end
  end

  defp authorized?(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> valid_token?(token)
      _other -> false
    end
  end

  defp valid_token?(token) do
    case Auth0Ex.verify_and_validate(token) do
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
