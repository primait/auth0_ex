defmodule Auth0Ex.Token do
  use Joken.Config

  add_hook(JokenJwks, strategy: Auth0Ex.JwksStrategy)

  @impl true
  def token_config do
    default_claims(iss: issuer(), aud: audience(), generate_jti: false)
  end

  defp audience, do: Application.fetch_env!(:auth0_ex, :auth0)[:audience]

  defp issuer, do: Application.fetch_env!(:auth0_ex, :auth0)[:issuer]
end
