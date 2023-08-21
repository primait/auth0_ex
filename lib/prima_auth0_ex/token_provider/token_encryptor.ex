defmodule PrimaAuth0Ex.TokenProvider.TokenEncryptor do
  @moduledoc """
  Module to perform authenticated symmetric encryption of binaries.

  The key used for encryption is set from config:

    config :prima_auth0_ex, :redis,
      encryption_key: "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA="
  """
  @aad "AES256GCM"

  @spec encrypt(String.t()) :: {:ok, String.t()} | {:error, any()}
  def encrypt(plaintext) do
    iv = :crypto.strong_rand_bytes(16)

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(
        :aes_256_gcm,
        token_encryption_key(),
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

  @spec decrypt(String.t()) :: {:ok, String.t()} | {:error, any()}
  def decrypt(encrypted) do
    <<iv::binary-16, tag::binary-16, ciphertext::binary>> = Base.decode64!(encrypted)

    case :crypto.crypto_one_time_aead(
           :aes_256_gcm,
           token_encryption_key(),
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

  defp token_encryption_key do
    encoded_key = Application.fetch_env!(:prima_auth0_ex, :redis)[:encryption_key]
    Base.decode64!(encoded_key)
  end
end
