defmodule Auth0Ex.Consumer.EncryptedRedisTokenCache do
  alias Auth0Ex.Consumer.TokenCache

  @behaviour TokenCache

  @cache_namespace Application.compile_env!(:auth0_ex, :redix_instance_name)
  @redix_instance_name Application.compile_env!(:auth0_ex, :redix_instance_name)
  @token_encryption_key Application.fetch_env!(:auth0_ex, :token_encryption_key) |> Base.decode64!()

  @aad "AES256GCM"

  @impl TokenCache
  def get_token_for(audience) do
    {:ok, encrypted} = Redix.command(@redix_instance_name, ["GET", key_for(audience)])
    token = decrypt(encrypted)

    {:ok, token}
  end

  @impl TokenCache
  def set_token_for(audience, token) do
    token
    |> encrypt()
    |> save(key_for(audience))
  end

  defp key_for(audience), do: "auth0ex_tokens:#{@cache_namespace}:#{audience}"

  defp encrypt(plaintext) do
    iv = :crypto.strong_rand_bytes(16)
    {ciphertext, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, @token_encryption_key, iv, plaintext, @aad, true)

    encrypted = iv <> tag <> ciphertext
    Base.encode64(encrypted)
  end

  defp decrypt(encrypted) do
    <<iv::binary-16, tag::binary-16, ciphertext::binary>> = Base.decode64!(encrypted)

    :crypto.crypto_one_time_aead(:aes_256_gcm, @token_encryption_key, iv, ciphertext, @aad, tag, false)
  end

  defp save(value, key) do
    Redix.command(@redix_instance_name, ["SET", key, value])
  end
end
