defmodule PrimaAuth0Ex.TokenProvider.TokenEncryptorTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias PrimaAuth0Ex.TestHelper
  alias PrimaAuth0Ex.TokenProvider.TokenEncryptor

  @test_client :test_client
  @token_encryption_key "eT4YutFXY/PCV5Kr6gBD/K2NxM60OqeXFux09te6Z80="

  test "encrypts and decrypts correctly" do
    TestHelper.set_client_env(@test_client, :cache_encryption_key, @token_encryption_key)

    plaintext = "test"

    {:ok, enc} = TokenEncryptor.encrypt(@test_client, plaintext)
    {:ok, dec} = TokenEncryptor.decrypt(@test_client, enc)

    assert plaintext == dec
  end

  test "decrypting returns with :error if key changes" do
    TestHelper.set_client_env(@test_client, :cache_encryption_key, @token_encryption_key)

    {:ok, enc} = TokenEncryptor.encrypt(@test_client, "test")

    new_key = generate_key()

    TestHelper.set_client_env(@test_client, :cache_encryption_key, new_key, reset?: false)

    assert {:error, _} = TokenEncryptor.decrypt(@test_client, enc)
  end

  test "encrypting returns with :error if key is not binary" do
    TestHelper.set_client_env(@test_client, :cache_encryption_key, 1234)

    assert {:error, _} = TokenEncryptor.encrypt(@test_client, "test")
  end

  test "decrypting returns with :error if key is not binary" do
    TestHelper.set_client_env(@test_client, :cache_encryption_key, @token_encryption_key)

    {:ok, enc} = TokenEncryptor.encrypt(@test_client, "test")

    TestHelper.set_client_env(@test_client, :cache_encryption_key, 1234, reset?: false)

    assert {:error, _} = TokenEncryptor.decrypt(@test_client, enc)
  end

  defp generate_key, do: Base.encode64(:crypto.strong_rand_bytes(32))
end
