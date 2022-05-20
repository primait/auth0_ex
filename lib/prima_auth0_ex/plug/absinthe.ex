defmodule PrimaAuth0Ex.Plug.Absinthe do
  @moduledoc false

  defmodule Context do
    @moduledoc false

    @type t :: %__MODULE__{
            dry_run: boolean(),
            permissions: [String.t()] | nil
          }
    defstruct dry_run: false,
              permissions: nil
  end

  defmodule CreateSecurityContext do
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

      Absinthe.Plug.put_options(conn,
        context: %Context{
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
  end

  defmodule RequirePermission do
    @moduledoc """
    Absinthe middleware that ensure the permission is included in the current security context.
    """

    require Logger

    @behaviour Absinthe.Middleware

    @impl true
    def call(
          resolution = %{context: %Context{dry_run: dry_run, permissions: permissions}},
          required_permission
        ) do
      cond do
        permissions != nil and required_permission in permissions ->
          resolution

        dry_run and permissions == nil ->
          resolution

        dry_run and permissions != nil ->
          Logger.warn("Received invalid token", required_permissions: [required_permission])
          resolution

        not dry_run ->
          Absinthe.Resolution.put_result(resolution, {:error, "unauthorized"})
      end
    end
  end
end
