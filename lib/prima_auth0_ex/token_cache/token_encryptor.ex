defmodule PrimaAuth0Ex.TokenCache.TokenEncryptor do
  @moduledoc """
  Module to perform authenticated symmetric encryption of tokens.
  """
  @aad "AES256GCM"

  @spec encrypt(String.t(), <<_::32>>) :: {:ok, String.t()} | {:error, any()}
  def encrypt(plaintext, key) do
    iv = :crypto.strong_rand_bytes(16)

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(
        :aes_256_gcm,
        key,
        iv,
        plaintext,
        @aad,
        true
      )

    encrypted = iv <> tag <> ciphertext
    {:ok, Base.encode64(encrypted)}
  rescue
    err -> {:error, err}
  end

  @spec decrypt(String.t(), <<_::32>>) :: {:ok, String.t()} | {:error, any()}
  def decrypt(encrypted, key) do
    <<iv::binary-16, tag::binary-16, ciphertext::binary>> = Base.decode64!(encrypted)

    case :crypto.crypto_one_time_aead(
           :aes_256_gcm,
           key,
           iv,
           ciphertext,
           @aad,
           tag,
           false
         ) do
      :error -> {:error, "Failed to decrypt token"}
      decrypted -> {:ok, decrypted}
    end
  rescue
    err -> {:error, err}
  end
end
