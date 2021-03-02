defmodule Auth0Ex.ConsumerTest do
  use ExUnit.Case

  import Hammox
  alias Auth0Ex.Consumer

  @sample_credentials %Auth0Ex.Auth0Credentials{
    base_url: "base_url",
    client_id: "client_id",
    client_secret: "client_secret"
  }

  @token_check_interval Application.fetch_env!(:auth0_ex, :token_check_interval)

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    {:ok, pid} = Consumer.start_link(%Consumer{credentials: @sample_credentials})

    {:ok, %{pid: pid}}
  end

  test "when no valid token can be found in memory or in cache, retrieves a new token and updates the cache",
       %{pid: pid} do
    token = "MY-TOKEN"

    expect(
      AuthorizationServiceMock,
      :retrieve_token,
      1,
      fn @sample_credentials, "target_audience" -> {:ok, token} end
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

  test "when a valid token is found in memory, return it", %{pid: pid} do
    token = "MY-TOKEN"
    initialize_for_audience("target_audience", token, pid)

    assert token == Consumer.token_for(pid, "target_audience")
  end

  test "periodically check for necessity to refresh its tokens", %{pid: pid} do
    token = "MY-TOKEN"
    initialize_for_audience("target_audience", token, pid)

    expect(RefreshStrategyMock, :should_refresh?, fn _ -> true end)
    expect(TokenCacheMock, :get_token_for, fn _ -> {:ok, token} end)
    expect(TokenCacheMock, :set_token_for, fn _, _ -> :ok end)

    expect(
      AuthorizationServiceMock,
      :retrieve_token,
      1,
      fn @sample_credentials, "target_audience" -> {:ok, "A-NEW-TOKEN"} end
    )

    :timer.sleep(@token_check_interval + 500)

    assert "A-NEW-TOKEN" == Consumer.token_for(pid, "target_audience")
  end

  test "if token has been updated on shared cache by someone else, do not refresh it", %{pid: pid} do
    token = "MY-TOKEN"
    initialize_for_audience("target_audience", token, pid)

    expect(RefreshStrategyMock, :should_refresh?, fn _ -> true end)

    expect(TokenCacheMock, :get_token_for, fn "target_audience" -> {:ok, "A-NEW-CACHED-TOKEN"} end)

    :timer.sleep(@token_check_interval + 500)

    assert "A-NEW-CACHED-TOKEN" == Consumer.token_for(pid, "target_audience")
  end

  defp initialize_for_audience(audience, token, pid) do
    expect(TokenCacheMock, :get_token_for, 1, fn ^audience -> {:ok, token} end)
    Consumer.token_for(pid, audience)
  end
end
