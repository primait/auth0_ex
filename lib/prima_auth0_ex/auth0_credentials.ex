defmodule PrimaAuth0Ex.Auth0Credentials do
  @moduledoc "Credentials to access Auth0"

  alias PrimaAuth0Ex.Config

  @type t :: %__MODULE__{
          client: atom(),
          base_url: String.t(),
          client_id: String.t(),
          client_secret: String.t()
        }
  @enforce_keys [:client, :base_url, :client_id, :client_secret]
  defstruct [:client, :base_url, :client_id, :client_secret]

  @spec from_env(atom()) :: __MODULE__.t()
  def from_env(name \\ :default_client)

  def from_env(:default_client) do
    client = Config.default_client()

    IO.inspect(client)

    %__MODULE__{
      client: :default_client,
      base_url: Keyword.get(client, :auth0_base_url),
      client_id: Keyword.get(client, :client_id),
      client_secret: Keyword.get(client, :client_secret)
    }
  end

  def from_env(name) do
    client = Config.clients(name)

    %__MODULE__{
      client: name,
      base_url: Keyword.get(client, :auth0_base_url),
      client_id: Keyword.get(client, :client_id),
      client_secret: Keyword.get(client, :client_secret)
    }
  end
end
