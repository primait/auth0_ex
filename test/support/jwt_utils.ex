defmodule Auth0Ex.TestSupport.JwtUtils do
  @test_signer Joken.Signer.create("HS256", "secret")

  def new_jwt_for(audience) do
    Joken.generate_and_sign!(%{}, %{"aud" => audience}, @test_signer)
  end
end
