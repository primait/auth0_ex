defmodule PrimaAuth0Ex.TokenProviderTest do
  use ExUnit.Case

  import Hammox
  alias PrimaAuth0Ex.{Auth0Credentials, TokenProvider}
  alias PrimaAuth0Ex.TokenProvider.TokenInfo

  @test_client :test_client
  @target_audience "target_audience"

  @sample_credentials %Auth0Credentials{
    client: @test_client,
    base_url: "base_url",
    client_id: "client_id",
    client_secret: "client_secret"
  }
  @sample_token %TokenInfo{jwt: "SAMPLE-TOKEN", issued_at: 123, expires_at: 234, kid: "valid-kid"}
  @another_sample_token %TokenInfo{
    jwt: "ANOTHER-SAMPLE-TOKEN",
    issued_at: 123,
    expires_at: 234,
    kid: "valid-kid"
  }

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    {:ok, pid} = TokenProvider.start_link(credentials: @sample_credentials)

    in_one_hour = Timex.shift(Timex.now(), hours: 1)
    stub(RefreshStrategyMock, :refresh_time_for, fn _ -> in_one_hour end)
    stub(JwksKidsFetcherMock, :fetch_kids, fn _ -> {:ok, ["valid-kid"]} end)

    {:ok, %{pid: pid}}
  end

  test "the first time a token for an audience is requested, the token is retrieved externally",
       %{pid: pid} do
    expect(TokenServiceMock, :retrieve_token, fn @sample_credentials, @target_audience ->
      {:ok, @sample_token}
    end)

    assert {:ok, "SAMPLE-TOKEN"} == TokenProvider.token_for(pid, @target_audience)
  end

  @tag capture_log: true
  test "if the first retrieval of the token fails, returns error", %{pid: pid} do
    expect(TokenServiceMock, :retrieve_token, fn @sample_credentials, @target_audience ->
      {:error, :error_description}
    end)

    assert {:error, _} = TokenProvider.token_for(pid, @target_audience)
  end

  test "when a valid token is found in memory, returns it", %{pid: pid} do
    initialize_for_audience(@target_audience, @sample_token, pid)

    assert {:ok, "SAMPLE-TOKEN"} == TokenProvider.token_for(pid, @target_audience)
  end

  test "does not refresh token unless necessary", %{pid: pid} do
    sometime_after_next_check = Timex.shift(Timex.now(), hours: 1)
    expect(RefreshStrategyMock, :refresh_time_for, 1, fn _ -> sometime_after_next_check end)

    initialize_for_audience(@target_audience, @sample_token, pid)

    stub(TokenServiceMock, :refresh_token, fn _, _, _, _ -> {:ok, @another_sample_token} end)

    wait_for_first_check_to_complete()

    assert {:ok, "SAMPLE-TOKEN"} == TokenProvider.token_for(pid, @target_audience)
  end

  test "refreshes its tokens when necessary", %{pid: pid} do
    before_next_check = Timex.shift(Timex.now(), milliseconds: token_check_interval() - 100)
    expect(RefreshStrategyMock, :refresh_time_for, 2, fn _ -> before_next_check end)

    initialize_for_audience(@target_audience, @sample_token, pid)

    expect(
      TokenServiceMock,
      :refresh_token,
      fn @sample_credentials, @target_audience, @sample_token, false ->
        {:ok, @another_sample_token}
      end
    )

    wait_for_first_check_to_complete()

    assert {:ok, "ANOTHER-SAMPLE-TOKEN"} == TokenProvider.token_for(pid, @target_audience)
  end

  test "refreshes its tokens when their signature is not valid (eg. for keys revoked)", %{
    pid: pid
  } do
    sometime_after_next_check = Timex.shift(Timex.now(), hours: 1)
    expect(RefreshStrategyMock, :refresh_time_for, 2, fn _ -> sometime_after_next_check end)

    initialize_for_audience(@target_audience, @sample_token, pid)

    expect(JwksKidsFetcherMock, :fetch_kids, fn _credentials -> {:ok, ["different-kids"]} end)

    expect(
      TokenServiceMock,
      :refresh_token,
      fn @sample_credentials, @target_audience, @sample_token, false ->
        {:ok, @another_sample_token}
      end
    )

    wait_for_first_signature_check_to_complete()

    assert {:ok, "ANOTHER-SAMPLE-TOKEN"} == TokenProvider.token_for(pid, @target_audience)
  end

  test "can force refresh of token", %{pid: pid} do
    initialize_for_audience(@target_audience, @sample_token, pid)

    expect(
      TokenServiceMock,
      :refresh_token,
      fn @sample_credentials, @target_audience, _, true -> {:ok, @another_sample_token} end
    )

    assert {:ok, "ANOTHER-SAMPLE-TOKEN"} = TokenProvider.refresh_token_for(pid, @target_audience)
    assert {:ok, "ANOTHER-SAMPLE-TOKEN"} = TokenProvider.token_for(pid, @target_audience)
  end

  defp initialize_for_audience(audience, token, pid) do
    expect(TokenServiceMock, :retrieve_token, fn %Auth0Credentials{}, ^audience ->
      {:ok, token}
    end)

    TokenProvider.token_for(pid, audience)
  end

  defp wait_for_first_check_to_complete, do: :timer.sleep(token_check_interval() + 500)

  defp token_check_interval,
    do: Application.fetch_env!(:prima_auth0_ex, @test_client)[:token_check_interval]

  defp wait_for_first_signature_check_to_complete,
    do: :timer.sleep(signature_check_interval() + 500)

  defp signature_check_interval,
    do: Application.fetch_env!(:prima_auth0_ex, @test_client)[:signature_check_interval]
end
