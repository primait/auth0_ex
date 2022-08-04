defmodule PrimaAuth0Ex.TokenProvider.TokenEncryptorTest do
  use ExUnit.Case, async: false

  alias PrimaAuth0Ex.TestHelper
  alias PrimaAuth0Ex.TokenProvider.TokenEncryptor

  @token_encryption_key "eT4YutFXY/PCV5Kr6gBD/K2NxM60OqeXFux09te6Z80="

  test "encrypts and decrypts correctly" do
    TestHelper.set_client_env(:cache_encryption_key, @token_encryption_key, true)

    plaintext = "test"

    {:ok, enc} = TokenEncryptor.encrypt(plaintext)
    {:ok, dec} = TokenEncryptor.decrypt(enc)

    assert plaintext == dec
  end

  test "decrypting fails with :error if key changes" do
    TestHelper.set_client_env(:cache_encryption_key, @token_encryption_key, true)

    plaintext = "test"

    {:ok, enc} = TokenEncryptor.encrypt(plaintext)

    new_key = keygen()

    TestHelper.set_client_env(:cache_encryption_key, new_key, false)

    assert {:error, _} = TokenEncryptor.decrypt(enc)
  end

  defp keygen(), do: :crypto.strong_rand_bytes(32) |> Base.encode64()
end
