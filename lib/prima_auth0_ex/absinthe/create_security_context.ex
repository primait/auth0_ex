if Code.ensure_loaded?(Absinthe.Plug) do
  defmodule PrimaAuth0Ex.Absinthe.CreateSecurityContext do
    @moduledoc """
    Plug that reads the permissions from the received token and creates the security context.
    It does not validate the token!
    """

    @behaviour Plug

    @impl true
    def init(opts) do
      Keyword.merge([dry_run: dry_run()], opts)
    end

    @impl true
    def call(conn, dry_run: dry_run) do
      permissions =
        case Plug.Conn.get_req_header(conn, "authorization") do
          ["Bearer " <> token] -> PrimaAuth0Ex.Token.peek_permissions(token)
          [] -> nil
        end

      put_context(conn,
        auth0: %{
          permissions: permissions,
          dry_run: dry_run
        }
      )
    end

    defp dry_run do
      :prima_auth0_ex
      |> Application.get_env(:server, [])
      |> Keyword.get(:dry_run, false)
    end

    # Absinthe.Plug doesn't offer a way to access it's context
    def put_context(%Plug.Conn{private: %{absinthe: absinthe}} = conn, opts) do
      opts =
        absinthe
        |> Map.get(:context, %{})
        |> Map.merge(Enum.into(opts, %{}))
        |> then(&Map.merge(absinthe, %{context: &1}))

      Absinthe.Plug.put_options(conn, opts)
    end

    def put_context(conn, opts) do
      Absinthe.Plug.put_options(conn, %{context: Enum.into(opts, %{})})
    end
  end
end
