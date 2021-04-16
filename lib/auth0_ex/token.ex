defmodule Auth0Ex.Token do
  @moduledoc """
  Module to verify the integrity and validate the claims of tokens.
  """

  use Joken.Config

  add_hook JokenJwks, strategy: Auth0Ex.JwksStrategy
  add_hook Joken.Hooks.RequiredClaims, [:aud, :iat, :exp]

  @impl true
  def token_config do
    [skip: [:audience], iss: issuer()]
    |> default_claims()
    |> add_claim("aud", nil, &validate_audience/3)
    |> add_claim("permissions", nil, &validate_permissions/3)
  end

  @impl Joken.Hooks
  def after_validate(_hook_options, {:ok, claims} = result, {_token_config, _claims, context} = input) do
    if missing_required_permissions_claim?(claims, context) do
      {:halt, {:error, [message: "Invalid token", missing_claims: "permissions"]}}
    else
      {:cont, result, input}
    end
  end

  def after_validate(_, result, input), do: {:cont, result, input}

  @spec verify_and_validate_token(String.t(), String.t(), list(String.t()), boolean()) ::
          {:ok, Joken.claims()} | {:error, atom | Keyword.t()}
  def verify_and_validate_token(token, audience, required_permissions, ignore_signature) do
    context = %{audience: audience, required_permissions: required_permissions}

    if ignore_signature do
      validate_token(token, context)
    else
      verify_and_validate(token, __default_signer__(), context)
    end
  end

  @doc """
  Returns the list of permissions held by a token.

  In case of missing permissions claim or malformed token it defaults to an empty list.
  Note that this function does not verify the signature of the token.
  """
  @spec peek_permissions(String.t()) :: [String.t()]
  def peek_permissions(token) do
    with {:ok, claims} <- Joken.peek_claims(token),
         permissions <- Map.get(claims, "permissions", []) do
      permissions
    else
      _any_error -> []
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

  defp missing_required_permissions_claim?(claims, context) do
    permissions_required? =
      context
      |> Map.get(:required_permissions, [])
      |> Enum.count()
      |> Kernel.>(0)

    permissions_required? and not Map.has_key?(claims, "permissions")
  end
end
