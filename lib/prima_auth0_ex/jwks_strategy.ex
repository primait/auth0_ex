defmodule PrimaAuth0Ex.JwksStrategy do
  @moduledoc """
  Strategy used by `Joken` to obtain JWKS from Auth0.
  """

  alias PrimaAuth0Ex.Config

  use JokenJwks.DefaultStrategyTemplate

  def init_opts(opts) do
    Keyword.merge(opts, jwks_url: jwks_url())
  end

  defp jwks_url, do: base_url() <> "/.well-known/jwks.json"

  defp base_url, do: Config.server!(:auth0_base_url)
end
