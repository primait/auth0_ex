defmodule Integration.TokenProvider.MultiClientsTest do
  use ExUnit.Case, async: true

  import PrimaAuth0Ex.TestSupport.TimeUtils
  alias PrimaAuth0Ex.TokenProvider.{EncryptedRedisTokenCache, TokenInfo}

  @test_audience "redis-integration-test-audience"
  @test_client :test_client
  @other_test_client :other_test_client
  @clients [@test_client, @other_test_client]

  setup do
    Application.put_env(:prima_auth0_ex, :clients, @clients)

    :ok = Application.stop(:prima_auth0_ex)
    :ok = Application.start(:prima_auth0_ex)

    IO.inspect("here")

    for client <- @clients do
      redis_connection_uri = Application.fetch_env!(:prima_auth0_ex, client)[:redis_connection_uri]

      IO.inspect(client)

      redix_client_name = :"#{client}_redix"
      IO.inspect(redix_client_name)
      Redix.start_link(redis_connection_uri, name: redix_client_name)
      Redix.command!(redix_client_name, ["DEL", token_key(client, @test_audience)])
    end

    :ok
  end

  test "persists and retrieves tokens for multiple clients" do
    token = sample_token()
    :ok = EncryptedRedisTokenCache.set_token_for(@test_client, @test_audience, token)

    assert {:ok, token} == EncryptedRedisTokenCache.get_token_for(@test_client, @test_audience)

    assert {:ok, token} ==
             EncryptedRedisTokenCache.get_token_for(@other_test_client, @test_audience)
  end

  # test "retrieves tokens set by a previous version of prima_auth0_ex, hence without kid" do
  #   issued_at = one_hour_ago()
  #   expires_at = in_one_hour()
  #   token_without_kid = %{jwt: "my-token", issued_at: issued_at, expires_at: expires_at}
  #   :ok = EncryptedRedisTokenCache.set_token_for(@test_audience, token_without_kid)

  #   assert {:ok, %TokenInfo{jwt: "my-token", issued_at: ^issued_at, expires_at: ^expires_at, kid: nil}} =
  #            EncryptedRedisTokenCache.get_token_for(@test_audience)
  # end

  # test "returns {:ok, nil} when token is not cached" do
  #   assert {:ok, nil} == EncryptedRedisTokenCache.get_token_for(@test_audience)
  # end

  # test "encrypts tokens" do
  #   :ok = EncryptedRedisTokenCache.set_token_for(@test_audience, sample_token())

  #   persisted_token = Redix.command!(PrimaAuth0Ex.Redix, ["GET", token_key(@test_audience)])

  #   assert is_binary(persisted_token)
  #   assert {:error, _} = Jason.decode(persisted_token)
  # end

  # @tag capture_log: true
  # test "returns error when persisted tokens are invalid and could not be decrypted" do
  #   # this may happen e.g., if the secret key changes
  #   Redix.command!(PrimaAuth0Ex.Redix, [
  #     "SET",
  #     token_key(@test_audience),
  #     "malformed-encrypted-token"
  #   ])

  #   assert {:error, _} = EncryptedRedisTokenCache.get_token_for(@test_audience)
  # end

  # test "tokens are deleted from cache when they expire" do
  #   token = %TokenInfo{sample_token() | expires_at: in_two_seconds()}
  #   :ok = EncryptedRedisTokenCache.set_token_for(@test_audience, token)

  #   assert {:ok, ^token} = EncryptedRedisTokenCache.get_token_for(@test_audience)
  #   :timer.sleep(2100)
  #   assert {:ok, nil} = EncryptedRedisTokenCache.get_token_for(@test_audience)
  # end

  defp sample_token do
    %TokenInfo{
      jwt: "my-token",
      issued_at: one_hour_ago(),
      expires_at: in_one_hour(),
      kid: "my-kid"
    }
  end

  defp token_key(client, audience), do: "prima_auth0_ex_tokens:#{namespace(client)}:#{audience}"
  defp namespace(client), do: Application.fetch_env!(:prima_auth0_ex, client)[:cache_namespace]

  defp in_two_seconds, do: Timex.now() |> Timex.shift(seconds: 2) |> Timex.to_unix()
end
