defmodule Auth0Ex.TestSupport.JwtUtils do
  @moduledoc false

  @test_signer Joken.Signer.create("HS256", "secret")

  @days 60 * 60 * 24

  @spec jwt_with_claims(map()) :: String.t()
  def jwt_with_claims(claims) do
    Joken.generate_and_sign!(
      %{},
      claims,
      @test_signer
    )
  end

  def generate_fake_jwt(claims, extra_headers \\ %{}) do
    signer = Joken.Signer.create("HS256", "secret", extra_headers)

    Joken.generate_and_sign!(
      %{},
      claims,
      signer
    )
  end

  @spec jwt_that_expires_in(integer(), String.t()) :: String.t()
  def jwt_that_expires_in(time_seconds, audience) do
    expiration = Joken.current_time() + time_seconds
    one_day_before_expiration = expiration - 1 * @days

    Joken.generate_and_sign!(
      %{},
      %{"iat" => one_day_before_expiration, "exp" => expiration, "aud" => audience},
      @test_signer
    )
  end
end
