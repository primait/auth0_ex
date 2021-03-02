defmodule Auth0Ex.ConsumerTest do
  use ExUnit.Case

  import Hammox
  alias Auth0Ex.{Auth0Credentials, Consumer}

  @sample_credentials %Auth0Credentials{base_url: "base_url", client_id: "client_id", client_secret: "client_secret"}

  @token_check_interval Application.fetch_env!(:auth0_ex, :token_check_interval)

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    {:ok, pid} = Consumer.start_link(%Consumer{credentials: @sample_credentials})

    {:ok, %{pid: pid}}
  end

  test "the first time a token for an audience is requested, the token is retrieved externally", %{pid: pid} do
    expect(TokenServiceMock, :retrieve_token, fn @sample_credentials, "target_audience" -> {:ok, "MY-TOKEN"} end)

    assert "MY-TOKEN" == Consumer.token_for(pid, "target_audience")
  end

  test "when a valid token is found in memory, returns it", %{pid: pid} do
    initialize_for_audience("target_audience", "MY-TOKEN", pid)

    assert "MY-TOKEN" == Consumer.token_for(pid, "target_audience")
  end

  test "periodically checks for necessity to refresh its tokens", %{pid: pid} do
    initialize_for_audience("target_audience", "INITIAL-TOKEN", pid)

    expect(RefreshStrategyMock, :should_refresh?, fn _ -> true end)

    expect(
      TokenServiceMock,
      :refresh_token,
      fn @sample_credentials, "target_audience", "INITIAL-TOKEN" -> {:ok, "A-NEW-TOKEN"} end
    )

    wait_for_first_check_to_complete()

    assert "A-NEW-TOKEN" == Consumer.token_for(pid, "target_audience")
  end

  defp initialize_for_audience(audience, token, pid) do
    expect(TokenServiceMock, :retrieve_token, fn %Auth0Credentials{}, ^audience -> {:ok, token} end)

    Consumer.token_for(pid, audience)
  end

  defp wait_for_first_check_to_complete, do: :timer.sleep(@token_check_interval + 500)
end
