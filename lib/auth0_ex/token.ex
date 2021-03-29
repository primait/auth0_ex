defmodule Auth0Ex.Token do
  @moduledoc """
  Module to verify the integrity and validate the claims of tokens.
  """

  use Joken.Config

  add_hook(JokenJwks, strategy: Auth0Ex.JwksStrategy)

  @impl true
  def token_config do
    [skip: [:audience], iss: issuer()]
    |> default_claims()
    |> add_claim("aud", nil, &validate_audience/3)
    |> add_claim("permissions", nil, &validate_permissions/3)
  end

  @spec verify_and_validate_token(String.t(), String.t(), list(String.t()), boolean()) ::
          {:ok, Joken.claims()} | {:error, atom | Keyword.t()}
  def verify_and_validate_token(token, audience, required_permissions, verify_signature) do
    context = %{audience: audience, required_permissions: required_permissions}

    if verify_signature do
      verify_and_validate(token, __default_signer__(), context)
    else
      validate_token(token, context)
    end
  end

  defp validate_token(token, context) do
    with {:ok, claims} <- Joken.peek_claims(token),
         do: validate(claims, context)
  end

  defp issuer, do: Application.fetch_env!(:auth0_ex, :server)[:issuer]

  defp validate_audience(token_audience, _claims, context) do
    expected_audience = context[:audience]

    unless expected_audience do
      raise ArgumentError, "It is required to set an expected audience in order to validate tokens"
    end

    do_validate_audience(token_audience, expected_audience)
  end

  defp do_validate_audience(found, expected) when is_list(found), do: expected in found
  defp do_validate_audience(found, expected), do: found == expected

  defp validate_permissions(token_permissions, _claims, context) do
    required_permissions = context[:required_permissions]

    Enum.all?(required_permissions, &(&1 in token_permissions))
  end
end
