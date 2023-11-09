defmodule PrimaAuth0Ex.TokenCache.TokenEncryptorTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias PrimaAuth0Ex.TokenCache.TokenEncryptor

  @token_encryption_key :crypto.strong_rand_bytes(32)

  test "encrypts and decrypts correctly" do
    plaintext = "test"

    {:ok, enc} = TokenEncryptor.encrypt(plaintext, @token_encryption_key)
    {:ok, dec} = TokenEncryptor.decrypt(enc, @token_encryption_key)

    assert plaintext == dec
  end

  test "decrypting returns with :error if key changes" do
    {:ok, enc} = TokenEncryptor.encrypt("test", @token_encryption_key)

    new_key = generate_key()

    assert {:error, _} = TokenEncryptor.decrypt(enc, new_key)
  end

  test "encrypting returns with :error if key is not binary" do
    assert {:error, _} = TokenEncryptor.encrypt("test", 1234)
  end

  test "decrypting returns with :error if key is not binary" do
    {:ok, enc} = TokenEncryptor.encrypt("test", @token_encryption_key)

    assert {:error, _} = TokenEncryptor.decrypt(enc, 1234)
  end

  defp generate_key, do: :crypto.strong_rand_bytes(32)
end
