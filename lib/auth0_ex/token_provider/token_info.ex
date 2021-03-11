defmodule Auth0Ex.TokenProvider.TokenInfo do
  @enforce_keys [:jwt, :issued_at, :expires_at]
  @derive Jason.Encoder
  defstruct [:jwt, :issued_at, :expires_at]

  @type t() :: %__MODULE__{jwt: String.t(), issued_at: non_neg_integer(), expires_at: non_neg_integer()}

  def from_jwt(jwt) do
    {:ok, %{"iat" => issued_at, "exp" => expires_at}} = Joken.peek_claims(jwt)

    %__MODULE__{jwt: jwt, issued_at: issued_at, expires_at: expires_at}
  end
end
