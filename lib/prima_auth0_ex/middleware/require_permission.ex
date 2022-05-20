defmodule PrimaAuth0Ex.Middleware.RequirePermissions do
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
        required_permissions
      ) do
    permissions
    |> has_required_permissions?(required_permissions)
    |> then(fn has_required_permissions? ->
      # On dry-run, log a warning if token doesn't have required permission
      # but permissions was not nil (i.e. it was supposed to work)
      if not has_required_permissions? and permissions != nil and dry_run do
        Logger.warn("Received invalid token", required_permissions: required_permissions)
      end

      has_required_permissions?
    end)
    |> resolve(dry_run, resolution)
  end

  @spec has_required_permissions?(permissions :: [any()] | nil, required_permissions :: [any()] | nil) :: boolean()
  defp has_required_permissions?(nil, _), do: false
  defp has_required_permissions?(_, nil), do: false

  defp has_required_permissions?(permissions, required_permissions),
    do: Enum.all?(required_permissions, fn required_permission -> required_permission in permissions end)

  @spec resolve(has_required_permission? :: boolean(), dry_run :: boolean(), resolution :: Resolution.t()) ::
          Resolution.t()
  defp resolve(true, _, resolution), do: resolution
  defp resolve(false, true, resolution), do: resolution
  defp resolve(false, false, resolution), do: Absinthe.Resolution.put_result(resolution, {:error, "unauthorized"})
end
