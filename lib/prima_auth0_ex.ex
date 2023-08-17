defmodule PrimaAuth0Ex do
  @moduledoc """
  Handles the retrieval of token from Auth0 and their verification/validation.
  """

  alias PrimaAuth0Ex.{Token, TokenProvider}

  @doc """
  Obtain a token for the given audience.
  """
  @spec token_for(atom(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def token_for(client \\ :client, audience) do
    TokenProvider.token_for(client, audience)
  end

  @doc """
  Force the refresh of the token for a given audience, invalidating both the local and the shared cache.
  """
  @spec refresh_token_for(atom(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def refresh_token_for(client \\ :client, audience) do
    TokenProvider.refresh_token_for(client, audience)
  end

  @doc """
  Verify the integrity of a token, and validate its claims.

  It is possible to set a list of permissions to validate.
  Only tokens that include all the required permissions will pass validation.

  When `ignore_signature` is `true`, only checks the validity of claims of the token and not its signature.
  This option should never be enabled in production-like environments, as it allows anyone to forge valid tokens.
  """
  @spec verify_and_validate(String.t(), String.t()) :: {:ok, Joken.claims()} | {:error, atom | Keyword.t()}
  @spec verify_and_validate(String.t(), String.t(), list(String.t())) ::
          {:ok, Joken.claims()} | {:error, atom | Keyword.t()}
  @spec verify_and_validate(String.t(), String.t(), list(String.t()), boolean()) ::
          {:ok, Joken.claims()} | {:error, atom | Keyword.t()}
  def verify_and_validate(token, audience, permissions \\ [], ignore_signature \\ false) do
    Token.verify_and_validate_token(token, audience, permissions, ignore_signature)
  end
end
