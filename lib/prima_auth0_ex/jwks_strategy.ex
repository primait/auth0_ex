defmodule PrimaAuth0Ex.JwksStrategy do
  @moduledoc """
  Strategy used by `Joken` to obtain JWKS from Auth0.
  """

  alias PrimaAuth0Ex.Config

  use JokenJwks.DefaultStrategyTemplate

  def init_opts(opts) do
    Keyword.merge(opts, jwks_url: jwks_url())
  end

  defp jwks_url do
    %HTTPoison.Response{status_code: status_code, body: meta_body} = Telepoison.get!(oidc_metadata_url())
    true = status_code in 200..299

    meta_body
    |> Jason.decode!()
    |> Map.fetch!("jwks_uri")
  end

  defp base_url, do: Config.server!(:auth0_base_url)
  defp oidc_metadata_url, do: base_url() <> "/.well-known/openid-configuration"
end
