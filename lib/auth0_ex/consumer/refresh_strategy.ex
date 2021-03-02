defmodule Auth0Ex.Consumer.RefreshStrategy do
  @callback should_refresh?(String.t()) :: boolean()
end
