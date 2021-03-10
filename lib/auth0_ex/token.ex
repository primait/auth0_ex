defmodule Auth0Ex.Token do
  use Joken.Config

  add_hook(JokenJwks, strategy: Auth0Ex.JwksStrategy)

  @impl true
  def token_config do
    [skip: [:audience], iss: issuer()]
    |> default_claims()
    |> add_claim("aud", nil, &validate_audience/3)
    |> add_claim("permissions", nil, &validate_permissions/3)
  end

  def verify_and_validate_token(token, audience, required_permissions \\ []) do
    verify_and_validate(token, __default_signer__(), %{audience: audience, required_permissions: required_permissions})
  end

  defp issuer, do: Application.fetch_env!(:auth0_ex, :auth0)[:issuer]

  defp validate_audience(token_audience, _claims, context) do
    expected_audience = context[:audience]

    unless expected_audience do
      raise ArgumentError, "It is required to set an expected audience in order to validate tokens"
    end

    token_audience == expected_audience
  end

  defp validate_permissions(token_permissions, _claims, context) do
    required_permissions = context[:required_permissions]

    Enum.all?(required_permissions, &(&1 in token_permissions))
  end
end
