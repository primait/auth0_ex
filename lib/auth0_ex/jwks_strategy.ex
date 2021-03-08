defmodule Auth0Ex.JwksStrategy do
  use JokenJwks.DefaultStrategyTemplate

  def init_opts(opts) do
    Keyword.merge(opts, jwks_url: jwks_url())
  end

  defp jwks_url, do: base_url() <> "/.well-known/jwks.json"

  def base_url, do: Application.fetch_env!(:auth0_ex, :auth0)[:base_url]
end
