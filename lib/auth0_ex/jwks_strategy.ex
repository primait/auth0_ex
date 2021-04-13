defmodule Auth0Ex.JwksStrategy do
  @moduledoc """
  Strategy used by `Joken` to obtain JWKS from Auth0.
  """

  use JokenJwks.DefaultStrategyTemplate

  def init_opts(opts) do
    Keyword.merge(opts, jwks_url: jwks_url())
  end

  def jwks_url, do: base_url() <> "/.well-known/jwks.json"

  defp base_url, do: Application.fetch_env!(:auth0_ex, :auth0_base_url)
end
