defmodule PrimaAuth0Ex.TokenProvider.TokenInfo do
  @moduledoc "Information related to a JWT, including the JWT itself and additional metadata"

  @enforce_keys [:jwt, :issued_at, :expires_at]
  @derive Jason.Encoder
  defstruct [:jwt, :kid, :issued_at, :expires_at]

  @type t :: %__MODULE__{
          jwt: String.t(),
          issued_at: non_neg_integer(),
          expires_at: non_neg_integer(),
          kid: String.t() | nil
        }

  @spec from_jwt(String.t()) :: __MODULE__.t()
  def from_jwt(jwt) do
    {:ok, %{"kid" => kid}} = Joken.peek_header(jwt)
    {:ok, %{"iat" => issued_at, "exp" => expires_at}} = Joken.peek_claims(jwt)

    %__MODULE__{jwt: jwt, issued_at: issued_at, expires_at: expires_at, kid: kid}
  end
end
