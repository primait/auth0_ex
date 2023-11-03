defmodule PrimaAuth0Ex.JwksStrategy do
  @moduledoc """
  Strategy used by `Joken` to obtain JWKS from Auth0.
  """

  alias PrimaAuth0Ex.Config

  alias PrimaAuth0Ex.OpenIDConfiguration
  use JokenJwks.DefaultStrategyTemplate

  def init_opts(opts) do
    jwks_url = Config.server(:auth0_base_url) |> OpenIDConfiguration.fetch!() |> Map.fetch!(:jwks_uri)
    Keyword.merge(opts, jwks_url: jwks_url)
  end
end
