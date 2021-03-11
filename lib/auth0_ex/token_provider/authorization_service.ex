defmodule Auth0Ex.TokenProvider.AuthorizationService do
  @moduledoc """
  Behaviour to handle communications with an authorization service.
  """
  alias Auth0Ex.TokenProvider.TokenInfo

  @callback retrieve_token(Auth0Ex.Auth0Credentials.t(), String.t()) :: {:ok, TokenInfo.t()} | {:error, atom()}
end
