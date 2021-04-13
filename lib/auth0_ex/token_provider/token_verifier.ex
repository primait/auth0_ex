defmodule Auth0Ex.TokenProvider.TokenVerifier do
  @moduledoc """
  Behaviour that validates signatures of a token against a public JWKS.
  """
  alias Auth0Ex.TokenProvider.TokenInfo

  @callback signature_valid?(TokenInfo.t()) :: boolean()
  @callback fetch_jwks() :: :ok
end
