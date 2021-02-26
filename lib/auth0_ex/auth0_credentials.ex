defmodule Auth0Ex.Auth0Credentials do
  @type t() :: %__MODULE__{base_url: String.t(), client_id: String.t(), client_secret: String.t()}
  @enforce_keys [:base_url, :client_id, :client_secret]
  defstruct [:base_url, :client_id, :client_secret]

  def from_env do
    %__MODULE__{
      base_url: Application.fetch_env!(:auth0_ex, :auth0)[:base_url],
      client_id: Application.fetch_env!(:auth0_ex, :auth0)[:client_id],
      client_secret: Application.fetch_env!(:auth0_ex, :auth0)[:client_secret]
    }
  end
end
