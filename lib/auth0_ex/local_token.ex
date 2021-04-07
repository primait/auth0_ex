defmodule Auth0Ex.LocalToken do
  @moduledoc """
  Utilities to help working with `auth0_ex` on a local environment, without the need to integrate with Auth0.
  """

  @signer Joken.Signer.create("HS256", "any-secret")

  @doc """
  Forge a token with the desired payload.

  The signature will be generated locally, hence it will **not** be valid.
  For this reason, this function should be used for local development only.
  """
  @spec forge(String.t(), Keyword.t()) :: String.t()
  def forge(audience, extra_claims \\ []) do
    claims = merge_claims(default_claims(audience), extra_claims)

    Joken.generate_and_sign!(
      %{},
      claims,
      @signer
    )
  end

  defp merge_claims(base_claims, extra_claims) do
    extra_claims =
      extra_claims
      |> Enum.map(fn {key, value} -> {Atom.to_string(key), value} end)
      |> Enum.into(%{})

    Map.merge(base_claims, extra_claims)
  end

  defp default_claims(audience) do
    %{"aud" => audience, "iat" => time_from_now(hours: -1), "exp" => time_from_now(hours: 1), "iss" => issuer()}
  end

  defp time_from_now(options) do
    Timex.now()
    |> Timex.shift(options)
    |> Timex.to_unix()
  end

  defp issuer, do: Application.fetch_env!(:auth0_ex, :server)[:issuer]
end
