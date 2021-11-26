defmodule PrimaAuth0Ex.Auth0Credentials do
  @moduledoc false

  @type t() :: %__MODULE__{base_url: String.t(), client_id: String.t(), client_secret: String.t()}
  @enforce_keys [:base_url, :client_id, :client_secret]
  defstruct [:base_url, :client_id, :client_secret]

  @spec from_env :: __MODULE__.t()
  def from_env do
    %__MODULE__{
      base_url: Application.fetch_env!(:prima_auth0_ex, :auth0_base_url),
      client_id: Application.fetch_env!(:prima_auth0_ex, :client)[:client_id],
      client_secret: Application.fetch_env!(:prima_auth0_ex, :client)[:client_secret]
    }
  end
end
