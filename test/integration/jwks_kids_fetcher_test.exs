defmodule Integration.TokenProvider.JwksKidsFetcherTest do
  use ExUnit.Case, async: true
  alias PrimaAuth0Ex.TokenProvider.Auth0JwksKidsFetcher

  @test_client_name :test_client

  @tag :external
  test "fetches list of currently valid kids" do
    credentials = PrimaAuth0Ex.Auth0Credentials.from_env(@test_client_name)

    assert {:ok, [kid | _rest]} = Auth0JwksKidsFetcher.fetch_kids(credentials)
    assert is_binary(kid)
  end
end
