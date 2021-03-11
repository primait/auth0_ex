defmodule Auth0Ex.TokenProvider.TokenService do
  alias Auth0Ex.Auth0Credentials
  alias Auth0Ex.TokenProvider.TokenInfo

  @callback retrieve_token(Auth0Credentials.t(), String.t()) :: {:ok, TokenInfo.t()} | {:error, any()}
  @callback refresh_token(Auth0Credentials.t(), String.t(), TokenInfo.t()) :: {:ok, TokenInfo.t()} | {:error, any()}
end
