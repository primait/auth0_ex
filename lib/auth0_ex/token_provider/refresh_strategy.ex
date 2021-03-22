defmodule Auth0Ex.TokenProvider.RefreshStrategy do
  @moduledoc """
  Behaviour to define a strategy to decide whether to refresh a token or keep using it for some more time.
  """

  alias Auth0Ex.TokenProvider.TokenInfo

  @callback should_refresh?(TokenInfo.t()) :: boolean()
end
