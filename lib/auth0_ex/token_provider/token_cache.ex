defmodule Auth0Ex.TokenProvider.TokenCache do
  @callback set_token_for(String.t(), String.t()) :: :ok | {:error, any()}
  @callback get_token_for(String.t()) :: {:ok, String.t() | nil} | {:error, any()}
end
