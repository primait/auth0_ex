defmodule PrimaAuth0Ex.Middleware.RequirePermission do
  @moduledoc """
  Absinthe middleware that ensure the permission is included in the current security context.
  """

  require Logger

  alias PrimaAuth0Ex.Plug.CreateSecurityContext.Context

  @behaviour Absinthe.Middleware

  @impl true
  def call(
        %{context: %Context{dry_run: dry_run, permissions: permissions}} = resolution,
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
