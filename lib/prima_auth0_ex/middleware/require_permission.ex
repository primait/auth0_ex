defmodule PrimaAuth0Ex.Middleware.RequirePermission do
  @moduledoc """
  Absinthe middleware that ensure the permission is included in the current security context.
  """

  require Logger

  alias Absinthe.Resolution
  alias PrimaAuth0Ex.Plug.CreateSecurityContext.Context

  @behaviour Absinthe.Middleware

  @impl true
  def call(
        %{context: %Context{dry_run: dry_run, permissions: permissions}} = resolution,
        required_permission
      ) do
    permissions
    |> has_required_permission?(required_permission)
    |> then(fn has_required_permissions? ->
      # On dry-run, log a warning if token doesn't have required permission
      # but permissions was not nil (i.e. it was supposed to work)
      if not has_required_permissions? and permissions != nil and dry_run do
        Logger.warn("Received invalid token", required_permission: required_permission)
      end

      has_required_permissions?
    end)
    |> resolve(dry_run, resolution)
  end

  @spec has_required_permission?(permissions :: [any()] | nil, required_permission :: any()) :: boolean()
  defp has_required_permission?(nil, _), do: false
  defp has_required_permission?(_, nil), do: false
  defp has_required_permission?(permissions, required_permission), do: required_permission in permissions

  @spec resolve(has_required_permission? :: boolean(), dry_run :: boolean(), resolution :: Resolution.t()) ::
          Resolution.t()
  defp resolve(true, _, resolution), do: resolution
  defp resolve(false, true, resolution), do: resolution
  defp resolve(false, false, resolution), do: Absinthe.Resolution.put_result(resolution, {:error, "unauthorized"})
end
