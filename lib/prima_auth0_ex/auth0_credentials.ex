defmodule PrimaAuth0Ex.Auth0Credentials do
  @moduledoc "Credentials to access Auth0"

  @type t :: %__MODULE__{base_url: String.t(), client_id: String.t(), client_secret: String.t()}
  @enforce_keys [:base_url, :client_id, :client_secret]
  defstruct [:base_url, :client_id, :client_secret]

  @spec from_env :: __MODULE__.t()
  def from_env(name) do
    clients = Application.fetch_env!(:prima_auth0_ex, :clients)
    client = Map.fetch!(clients, name)

    %__MODULE__{
      base_url: Keyword.get(client, :auth0_base_url),
      client_id: Keyword.get(client, :client_id),
      client_secret: Keyword.get(client, :client_secret)
    }
  end
end
