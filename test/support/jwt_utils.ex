defmodule Auth0Ex.TestSupport.JwtUtils do
  @test_signer Joken.Signer.create("HS256", "secret")

  @days 60 * 60 * 24

  def new_jwt_for(audience) do
    Joken.generate_and_sign!(%{}, %{"aud" => audience}, @test_signer)
  end

  def jwt_that_expires_in(time_seconds) do
    expiration = Joken.current_time() + time_seconds
    one_day_before_expiration = expiration - 1 * @days

    Joken.generate_and_sign!(
      %{},
      %{"iat" => one_day_before_expiration, "exp" => expiration},
      @test_signer
    )
  end

  def expired_jwt(audience \\ "audience") do
    three_days_ago = Joken.current_time() - 3 * @days
    two_days_ago = Joken.current_time() - 2 * @days

    Joken.generate_and_sign!(
      %{},
      %{"iat" => three_days_ago, "exp" => two_days_ago, "aud" => audience},
      @test_signer
    )
  end
end
