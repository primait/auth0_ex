defmodule Auth0Ex.TokenProvider.AuthorizationService do
  @callback retrieve_token(Auth0Ex.Auth0Credentials.t(), String.t()) :: {:ok, String.t()} | {:error, atom()}
end
