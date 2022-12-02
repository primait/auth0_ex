if Code.ensure_loaded?(Absinthe) and Code.ensure_loaded?(Absinthe.Plug) do
  defmodule PrimaAuth0Ex.Absinthe.RequirePermissions do
    @moduledoc """
    Absinthe middleware that ensures that the given token permissions are included in the current security context.
    If this is not the case, it returns an `unauthorized` error.

    If prima_auth0_ex is configured to run in "dry run" mode, this middleware simply logs a warning when the context doesn't include the given permissions.

    This is meant to be used in conjunction with the `PrimaAuth0Ex.Absinthe.CreateSecurityContext` plug.
    """

    require Logger

    alias PrimaAuth0Ex.Absinthe.CreateSecurityContext.Auth0

    @behaviour Absinthe.Middleware

    @impl true
    def call(
          %{context: %{auth0: %Auth0{permissions: permissions}}} = resolution,
          required_permissions
        ) do
      if has_required_permissions?(permissions, required_permissions) do
        resolution
      else
        resolve(resolution, required_permissions)
      end
    end

    defp has_required_permissions?(nil = _permissions, _required_permissions), do: false

    defp has_required_permissions?(permissions, required_permissions),
      do: Enum.all?(required_permissions, &Enum.member?(permissions, &1))

    defp resolve(
           %{context: %{auth0: %Auth0{dry_run: true, permissions: permissions}}} = resolution,
           required_permissions
         ) do
      if permissions != nil do
        Logger.warn("Received token with incorrect permissions",
          token_permissions: permissions,
          required_permissions: required_permissions
        )
      end

      resolution
    end

    defp resolve(%{context: %{auth0: %Auth0{dry_run: false}}} = resolution, _required_permissions),
      do: Absinthe.Resolution.put_result(resolution, {:error, "unauthorized"})
  end
end
