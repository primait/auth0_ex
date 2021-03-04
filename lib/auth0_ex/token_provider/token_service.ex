defmodule Auth0Ex.TokenProvider.TokenService do
  alias Auth0Ex.Auth0Credentials

  @callback retrieve_token(Auth0Credentials.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  @callback refresh_token(Auth0Credentials.t(), String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
end
