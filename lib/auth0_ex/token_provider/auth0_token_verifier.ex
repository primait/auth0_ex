defmodule Auth0Ex.TokenProvider.Auth0TokenVerifier do
  @moduledoc """
  Implementation of `Auth0Ex.TokenProvider.TokenVerifier` for Auth0 tokens.
  """
  alias Auth0Ex.TokenProvider.TokenInfo

  @behaviour Auth0Ex.TokenProvider.TokenVerifier

  @impl true
  def fetch_jwks do
    Auth0Ex.JwksStrategy.fetch_signers(Auth0Ex.JwksStrategy.jwks_url(), log_level: :none)
    :ok
  end

  @impl true
  def signature_valid?(%TokenInfo{jwt: jwt}) do
    case Auth0Ex.Token.verify(jwt) do
      {:ok, _claims} -> true
      {:error, _} -> false
    end
  end
end
