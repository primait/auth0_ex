defmodule Auth0Ex.TokenProvider.TokenVerifier do
  alias Auth0Ex.TokenProvider.TokenInfo

  @callback signature_valid?(TokenInfo.t()) :: boolean()
  @callback fetch_jwks() :: :ok
end
