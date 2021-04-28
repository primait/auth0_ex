defmodule Auth0Ex.TokenProvider.TokenInfoTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.TestSupport.JwtUtils
  alias Auth0Ex.TokenProvider.TokenInfo

  test "extracts metadata from token" do
    issued_at = Timex.now() |> Timex.shift(hours: -12) |> Timex.to_unix()
    expires_at = Timex.now() |> Timex.shift(hours: 12) |> Timex.to_unix()
    token = JwtUtils.generate_fake_jwt(%{iat: issued_at, exp: expires_at}, %{kid: "my-kid"})

    assert %TokenInfo{
             jwt: token,
             kid: "my-kid",
             issued_at: issued_at,
             expires_at: expires_at
           } == TokenInfo.from_jwt(token)
  end
end
