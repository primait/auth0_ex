if Code.ensure_loaded?(Absinthe.Plug) do
  defmodule PrimaAuth0Ex.Absinthe.CreateSecurityContext do
    @moduledoc """
    Plug that reads the permissions from the JWT token passed in the `Authorization` header and creates the security context.

    It does not validate the token! You should use the `PrimaAuth0Ex.Plug.VerifyAndValidateToken` plug to do that.
    """

    defmodule Auth0 do
      @moduledoc false

      @type t :: %__MODULE__{
              dry_run: boolean(),
              permissions: [String.t()] | nil
            }
      defstruct dry_run: false,
                permissions: nil
    end

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

      Absinthe.Plug.assign_context(conn,
        auth0: %Auth0{
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
end
