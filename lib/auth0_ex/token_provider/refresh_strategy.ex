defmodule Auth0Ex.TokenProvider.RefreshStrategy do
  alias Auth0Ex.TokenProvider.TokenInfo

  @callback should_refresh?(TokenInfo.t()) :: boolean()
end
