defmodule Auth0Ex.ConsumerTest do
  use ExUnit.Case, async: true

  import Hammox
  alias Auth0Ex.Consumer
  alias Auth0Ex.TestSupport.JwtUtils

  @sample_config %Consumer{
    base_url: "base_url",
    client_id: "client_id",
    client_secret: "client_secret"
  }

  setup :verify_on_exit!

  test "when no token for the given audience exists, retrieves and returns a new token" do
    token = JwtUtils.new_jwt_for("target_audience")

    expect(
      AuthorizationServiceMock,
      :retrieve_token,
      1,
      fn "base_url", "client_id", "client_secret", "target_audience" -> {:ok, token} end
    )

    {:ok, pid} = Consumer.start_link(@sample_config)

    allow(AuthorizationServiceMock, self(), pid)
    assert token == Consumer.token_for(pid, "target_audience")
  end

  test "stores tokens and reuses them as long as they are valid" do
    token = JwtUtils.new_jwt_for("target_audience")

    expect(
      AuthorizationServiceMock,
      :retrieve_token,
      1,
      fn "base_url", "client_id", "client_secret", "target_audience" -> {:ok, token} end
    )

    {:ok, pid} = Consumer.start_link(@sample_config)
    allow(AuthorizationServiceMock, self(), pid)
    Consumer.token_for(pid, "target_audience")

    assert token == Consumer.token_for(pid, "target_audience")
  end

  test "refreshes token for target audience synchronously when the persisted token is no longer valid" do
    expired_token = JwtUtils.expired_jwt_for("target_audience")
    token = JwtUtils.new_jwt_for("target_audience")

    expect(
      AuthorizationServiceMock,
      :retrieve_token,
      1,
      fn "base_url", "client_id", "client_secret", "target_audience" -> {:ok, token} end
    )

    {:ok, pid} =
      Consumer.start_link(%{@sample_config | tokens: %{"target_audience" => expired_token}})

    allow(AuthorizationServiceMock, self(), pid)

    assert token == Consumer.token_for(pid, "target_audience")
  end
end
