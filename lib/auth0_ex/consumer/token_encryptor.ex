defmodule Auth0Ex.Consumer.TokenEncryptor do
  @aad "AES256GCM"

  def encrypt(plaintext) do
    iv = :crypto.strong_rand_bytes(16)
    {ciphertext, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, token_encryption_key(), iv, plaintext, @aad, true)

    encrypted = iv <> tag <> ciphertext
    Base.encode64(encrypted)
  end

  def decrypt(encrypted) do
    <<iv::binary-16, tag::binary-16, ciphertext::binary>> = Base.decode64!(encrypted)

    :crypto.crypto_one_time_aead(:aes_256_gcm, token_encryption_key(), iv, ciphertext, @aad, tag, false)
  end

  defp token_encryption_key do
    encoded_key = Application.fetch_env!(:auth0_ex, :cache)[:encryption_key]
    Base.decode64!(encoded_key)
  end
end
