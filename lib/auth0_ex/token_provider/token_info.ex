defmodule Auth0Ex.TokenProvider.TokenInfo do
  @moduledoc false

  @enforce_keys [:jwt, :issued_at, :expires_at]
  @derive Jason.Encoder
  defstruct [:jwt, :issued_at, :expires_at]

  @typedoc """
  A JWT along with some useful metadata.
  """
  @type t() :: %__MODULE__{jwt: String.t(), issued_at: non_neg_integer(), expires_at: non_neg_integer()}

  @spec from_jwt(String.t()) :: __MODULE__.t()
  def from_jwt(jwt) do
    {:ok, %{"iat" => issued_at, "exp" => expires_at}} = Joken.peek_claims(jwt)

    %__MODULE__{jwt: jwt, issued_at: issued_at, expires_at: expires_at}
  end
end
