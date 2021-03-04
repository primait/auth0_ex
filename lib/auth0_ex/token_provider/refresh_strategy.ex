defmodule Auth0Ex.TokenProvider.RefreshStrategy do
  @callback should_refresh?(String.t()) :: boolean()
end
