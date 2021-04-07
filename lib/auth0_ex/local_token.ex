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
  def forge(audience) do
    Joken.generate_and_sign!(
      %{},
      %{"aud" => audience},
      @signer
    )
  end
end
