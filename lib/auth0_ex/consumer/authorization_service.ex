defmodule Auth0Ex.Consumer.AuthorizationService do
  @callback retrieve_token(String.t(), String.t(), String.t(), String.t()) ::
              {:ok, String.t()} | {:error, atom()}
end
