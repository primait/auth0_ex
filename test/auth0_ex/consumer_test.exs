defmodule Auth0Ex.ConsumerTest do
  use ExUnit.Case, async: true

  import Hammox
  alias Auth0Ex.Consumer

  setup :verify_on_exit!

  test "if no token for the given audience exists, retrieves and return a new token" do
    expect(
      AuthorizationServiceMock,
      :retrieve_token,
      1,
      fn "base_url", "client_id", "client_secret", "target_audience" -> {:ok, "my_token"} end
    )

    {:ok, pid} =
      Consumer.start_link(%Consumer{
        base_url: "base_url",
        client_id: "client_id",
        client_secret: "client_secret"
      })

    allow(AuthorizationServiceMock, self(), pid)
    assert "my_token" == Consumer.token_for(pid, "target_audience")
  end
end
