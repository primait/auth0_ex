defmodule PrimaAuth0Ex.TokenProvider.TokenCache do
  @moduledoc """
  Behaviour that defines a cache for tokens.
  """

  alias PrimaAuth0Ex.TokenProvider.TokenInfo

  @callback set_token_for(atom(), String.t(), TokenInfo.t()) :: :ok | {:error, any()}
  @callback get_token_for(atom(), String.t()) :: {:ok, TokenInfo.t() | nil} | {:error, any()}
end
