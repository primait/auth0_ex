defmodule Auth0Ex.TokenProvider.TokenCache do
  @moduledoc """
  Behaviour that defines a cache for tokens.
  """

  alias Auth0Ex.TokenProvider.TokenInfo

  @callback set_token_for(String.t(), TokenInfo.t()) :: :ok | {:error, any()}
  @callback get_token_for(String.t()) :: {:ok, TokenInfo.t() | nil} | {:error, any()}
end
