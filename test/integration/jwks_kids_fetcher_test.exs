defmodule Integration.TokenProvider.JwksKidsFetcherTest do
  use ExUnit.Case, async: true
  alias Auth0Ex.TokenProvider.JwksKidsFetcher

  @tag :external
  test "fetches list of currently valid kids" do
    credentials = Auth0Ex.Auth0Credentials.from_env()

    assert {:ok, [kid | _rest]} = JwksKidsFetcher.fetch_kids(credentials)
    assert is_binary(kid)
  end
end
