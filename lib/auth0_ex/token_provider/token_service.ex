defmodule Auth0Ex.TokenProvider.TokenService do
  @moduledoc """
  Behaviour to deal with retrieval and refresh of tokens
  """

  alias Auth0Ex.Auth0Credentials
  alias Auth0Ex.TokenProvider.TokenInfo

  @callback retrieve_token(Auth0Credentials.t(), String.t()) :: {:ok, TokenInfo.t()} | {:error, any()}
  @callback refresh_token(Auth0Credentials.t(), String.t(), TokenInfo.t() | nil, force_cache_bust :: boolean()) ::
              {:ok, TokenInfo.t()} | {:error, any()}
end
