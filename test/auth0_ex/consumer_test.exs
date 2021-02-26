defmodule Auth0Ex.ConsumerTest do
  use ExUnit.Case, async: true

  import Hammox
  alias Auth0Ex.Consumer

  @sample_config %Consumer{
    base_url: "base_url",
    client_id: "client_id",
    client_secret: "client_secret"
  }

  setup :verify_on_exit!

  setup do
    {:ok, pid} = Consumer.start_link(@sample_config)
    allow(AuthorizationServiceMock, self(), pid)
    allow(TokenCacheMock, self(), pid)

    {:ok, %{pid: pid}}
  end

  test "when no valid token can be found in memory or in cache, retrieves a new token and updates the cache",
       %{pid: pid} do
    token = "MY-TOKEN"

    expect(
      AuthorizationServiceMock,
      :retrieve_token,
      1,
      fn "base_url", "client_id", "client_secret", "target_audience" -> {:ok, token} end
    )

    expect(TokenCacheMock, :get_token_for, fn "target_audience" -> {:error, :not_found} end)
    expect(TokenCacheMock, :set_token_for, fn "target_audience", ^token -> :ok end)

    assert token == Consumer.token_for(pid, "target_audience")
  end

  test "when no valid token can be found in memory, try to retrieve it from cache", %{pid: pid} do
    token = "MY-TOKEN"

    expect(TokenCacheMock, :get_token_for, fn "target_audience" -> {:ok, token} end)

    assert token == Consumer.token_for(pid, "target_audience")
  end
end
