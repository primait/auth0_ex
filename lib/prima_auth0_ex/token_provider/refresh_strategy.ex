defmodule PrimaAuth0Ex.TokenProvider.RefreshStrategy do
  @moduledoc """
  Behaviour to define a strategy to decide whether to refresh a token or keep using it for some more time.
  """

  alias PrimaAuth0Ex.TokenProvider.TokenInfo

  @callback refresh_time_for(TokenInfo.t()) :: Timex.Types.valid_datetime()
end
