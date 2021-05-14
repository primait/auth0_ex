defmodule Auth0Ex.TestSupport.JwtUtils do
  @moduledoc false

  @days 60 * 60 * 24

  def jwt_that_expires_in(time_seconds, audience, extra_claims \\ %{}, extra_headers \\ %{}) do
    expiration = Joken.current_time() + time_seconds
    one_day_before_expiration = expiration - 1 * @days

    default_claims = %{"iat" => one_day_before_expiration, "exp" => expiration, "aud" => audience}
    claims = Map.merge(default_claims, extra_claims)

    generate_fake_jwt(audience, claims, extra_headers)
  end

  def generate_fake_jwt(audience, extra_claims \\ %{}, extra_headers \\ %{}) do
    expires_at = Joken.current_time() + 1 * @days
    issued_at = Joken.current_time() - 1 * @days
    default_claims = %{"iat" => issued_at, "exp" => expires_at, "aud" => audience}
    claims = Map.merge(default_claims, extra_claims)

    signer = Joken.Signer.create("HS256", "secret", extra_headers)

    Joken.generate_and_sign!(
      %{},
      claims,
      signer
    )
  end
end
