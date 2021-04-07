defmodule Auth0Ex.LocalTokenTest do
  use ExUnit.Case, async: true

  alias Auth0Ex.LocalToken

  test "by default forges a token for the given audience" do
    jwt = LocalToken.forge("audience")

    assert %{"aud" => "audience"} = claims_of(jwt)
  end

  defp claims_of(jwt) do
    {:ok, claims} = Joken.peek_claims(jwt)
    claims
  end
end
