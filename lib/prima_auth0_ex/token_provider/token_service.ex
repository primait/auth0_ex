defmodule PrimaAuth0Ex.TokenProvider.TokenService do
  @moduledoc """
  Behaviour to deal with retrieval and refresh of tokens
  """

  alias PrimaAuth0Ex.Auth0Credentials
  alias PrimaAuth0Ex.TokenProvider.TokenInfo

  @callback retrieve_token(Auth0Credentials.t(), String.t()) :: {:ok, TokenInfo.t()} | {:error, any()}
  @callback refresh_token(Auth0Credentials.t(), String.t(), TokenInfo.t() | nil, force_cache_bust :: boolean()) ::
              {:ok, TokenInfo.t()} | {:error, any()}
end
