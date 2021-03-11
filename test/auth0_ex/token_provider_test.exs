defmodule Auth0Ex.TokenProviderTest do
  use ExUnit.Case

  import Hammox
  alias Auth0Ex.{Auth0Credentials, TokenProvider}
  alias Auth0Ex.TokenProvider.TokenInfo

  @sample_credentials %Auth0Credentials{base_url: "base_url", client_id: "client_id", client_secret: "client_secret"}
  @sample_token %TokenInfo{jwt: "SAMPLE-TOKEN", issued_at: 123, expires_at: 234}
  @another_sample_token %TokenInfo{jwt: "ANOTHER-SAMPLE-TOKEN", issued_at: 123, expires_at: 234}

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    {:ok, pid} = TokenProvider.start_link(credentials: @sample_credentials)

    {:ok, %{pid: pid}}
  end

  test "the first time a token for an audience is requested, the token is retrieved externally", %{pid: pid} do
    expect(TokenServiceMock, :retrieve_token, fn @sample_credentials, "target_audience" -> {:ok, @sample_token} end)

    assert {:ok, @sample_token} == TokenProvider.token_for(pid, "target_audience")
  end

  test "if the first retrieval of the token fails, returns error", %{pid: pid} do
    expect(TokenServiceMock, :retrieve_token, fn @sample_credentials, "target_audience" ->
      {:error, :error_description}
    end)

    assert {:error, _} = TokenProvider.token_for(pid, "target_audience")
  end

  test "when a valid token is found in memory, returns it", %{pid: pid} do
    initialize_for_audience("target_audience", @sample_token, pid)

    assert {:ok, "SAMPLE-TOKEN"} == TokenProvider.token_for(pid, "target_audience")
  end

  test "refreshes its tokens when necessary", %{pid: pid} do
    initialize_for_audience("target_audience", @sample_token, pid)

    expect(RefreshStrategyMock, :should_refresh?, fn _ -> true end)

    expect(
      TokenServiceMock,
      :refresh_token,
      fn @sample_credentials, "target_audience", @sample_token -> {:ok, @another_sample_token} end
    )

    wait_for_first_check_to_complete()

    assert {:ok, "ANOTHER-SAMPLE-TOKEN"} == TokenProvider.token_for(pid, "target_audience")
  end

  defp initialize_for_audience(audience, token, pid) do
    expect(TokenServiceMock, :retrieve_token, fn %Auth0Credentials{}, ^audience -> {:ok, token} end)

    TokenProvider.token_for(pid, audience)
  end

  defp wait_for_first_check_to_complete, do: :timer.sleep(token_check_interval() + 500)

  defp token_check_interval, do: Application.fetch_env!(:auth0_ex, :client)[:token_check_interval]
end
