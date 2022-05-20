defmodule PrimaAuth0Ex.Plug.AbsintheTest do
  # , async: true
  use ExUnit.Case
  use Plug.Test

  alias Absinthe.Resolution
  alias PrimaAuth0Ex.Middleware.RequirePermissions
  alias PrimaAuth0Ex.Plug.CreateSecurityContext

  test "authorize request with right permissions" do
    opts = CreateSecurityContext.init([])

    %{private: %{absinthe: %{context: context}}} =
      :post
      |> conn("/graphql")
      |> put_req_header("authorization", "Bearer " <> generate_token_with_permissions(["read", "write", "delete"]))
      |> CreateSecurityContext.call(opts)

    resolution = %Resolution{context: context}
    assert resolution == RequirePermissions.call(resolution, ["read", "write"])
  end

  describe "do not authorize request without right permissions" do
    test "single permission must be in list" do
      opts = CreateSecurityContext.init([])

      %{private: %{absinthe: %{context: context}}} =
        :post
        |> conn("/graphql")
        |> put_req_header("authorization", "Bearer " <> generate_token_with_permissions(["read"]))
        |> CreateSecurityContext.call(opts)

      resolution = %Resolution{context: context}
      assert %Resolution{errors: ["unauthorized"]} = RequirePermissions.call(resolution, ["write"])
    end

    test "multiple permissions must ALL be included" do
      opts = CreateSecurityContext.init([])

      %{private: %{absinthe: %{context: context}}} =
        :post
        |> conn("/graphql")
        |> put_req_header("authorization", "Bearer " <> generate_token_with_permissions(["read", "write"]))
        |> CreateSecurityContext.call(opts)

      resolution = %Resolution{context: context}
      assert %Resolution{errors: ["unauthorized"]} = RequirePermissions.call(resolution, ["write", "delete"])
    end
  end

  test "do not authorize request without token" do
    opts = CreateSecurityContext.init(dry_run: false)

    %{private: %{absinthe: %{context: context}}} =
      :post
      |> conn("/graphql")
      |> CreateSecurityContext.call(opts)

    resolution = %Resolution{context: context}
    assert %Resolution{errors: ["unauthorized"]} = RequirePermissions.call(resolution, ["write"])
  end

  test "authorize request without token when dry-run is enabled" do
    opts = CreateSecurityContext.init(dry_run: true)

    %{private: %{absinthe: %{context: context}}} =
      :post
      |> conn("/graphql")
      |> CreateSecurityContext.call(opts)

    resolution = %Resolution{context: context}
    assert resolution == RequirePermissions.call(resolution, ["write"])
  end

  test "authorize request with bad token when dry-run is enabled" do
    opts = CreateSecurityContext.init(dry_run: true)

    %{private: %{absinthe: %{context: context}}} =
      :post
      |> conn("/graphql")
      |> put_req_header("authorization", "Bearer " <> generate_token_with_permissions(["read"]))
      |> CreateSecurityContext.call(opts)

    resolution = %Resolution{context: context}
    assert resolution == RequirePermissions.call(resolution, ["write"])
  end

  defp generate_token_with_permissions(permissions) do
    signer = Joken.Signer.create("HS256", "secret")
    Joken.generate_and_sign!(%{}, %{"permissions" => permissions}, signer)
  end
end
