defmodule PrimaAuth0Ex.Plug.AbsintheTest do
  # , async: true
  use ExUnit.Case
  use Plug.Test

  alias Absinthe.Resolution
  alias PrimaAuth0Ex.Plug.CreateSecurityContext
  alias PrimaAuth0Ex.Middleware.RequirePermission

  test "authorize request with right permission" do
    opts = CreateSecurityContext.init([])

    %{private: %{absinthe: %{context: context}}} =
      :post
      |> conn("/graphql")
      |> put_req_header("authorization", "Bearer " <> generate_token_with_permissions(["read"]))
      |> CreateSecurityContext.call(opts)

    resolution = %Resolution{context: context}
    assert resolution == RequirePermission.call(resolution, "read")
  end

  test "do not authorize request without right permission" do
    opts = CreateSecurityContext.init([])

    %{private: %{absinthe: %{context: context}}} =
      :post
      |> conn("/graphql")
      |> put_req_header("authorization", "Bearer " <> generate_token_with_permissions(["read"]))
      |> CreateSecurityContext.call(opts)

    resolution = %Resolution{context: context}
    assert %Resolution{errors: ["unauthorized"]} = RequirePermission.call(resolution, "write")
  end

  test "do not authorize request without token" do
    opts = CreateSecurityContext.init(dry_run: false)

    %{private: %{absinthe: %{context: context}}} =
      :post
      |> conn("/graphql")
      |> CreateSecurityContext.call(opts)

    resolution = %Resolution{context: context}
    assert %Resolution{errors: ["unauthorized"]} = RequirePermission.call(resolution, "write")
  end

  test "authorize request without token when dry-run is enabled" do
    opts = CreateSecurityContext.init(dry_run: true)

    %{private: %{absinthe: %{context: context}}} =
      :post
      |> conn("/graphql")
      |> CreateSecurityContext.call(opts)

    resolution = %Resolution{context: context}
    assert resolution == RequirePermission.call(resolution, "write")
  end

  test "authorize request with bad token when dry-run is enabled" do
    opts = CreateSecurityContext.init(dry_run: true)

    %{private: %{absinthe: %{context: context}}} =
      :post
      |> conn("/graphql")
      |> put_req_header("authorization", "Bearer " <> generate_token_with_permissions(["read"]))
      |> CreateSecurityContext.call(opts)

    resolution = %Resolution{context: context}
    assert resolution == RequirePermission.call(resolution, "write")
  end

  defp generate_token_with_permissions(permissions) do
    signer = Joken.Signer.create("HS256", "secret")
    Joken.generate_and_sign!(%{}, %{"permissions" => permissions}, signer)
  end
end
