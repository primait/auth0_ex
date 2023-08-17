defmodule PrimaAuth0Ex.TokenProvider.AuthorizationService do
  @moduledoc """
  Behaviour to handle communications with an authorization service.
  """
  alias PrimaAuth0Ex.TokenProvider.TokenInfo

  @callback retrieve_token(PrimaAuth0Ex.Auth0Credentials.t(), String.t()) ::
              {:ok, TokenInfo.t()} | {:error, atom()}
end
