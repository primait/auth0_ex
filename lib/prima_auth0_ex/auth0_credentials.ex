defmodule PrimaAuth0Ex.Auth0Credentials do
  @moduledoc "Credentials to access Auth0"

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
    client = Application.fetch_env!(:prima_auth0_ex, :client)

    %__MODULE__{
      client: :default_client,
      base_url: Keyword.get(client, :auth0_base_url),
      client_id: Keyword.get(client, :client_id),
      client_secret: Keyword.get(client, :client_secret)
    }
  end

  def from_env(name) do
    client = :prima_auth0_ex |> Application.fetch_env!(:clients) |> Keyword.get(name)

    %__MODULE__{
      client: name,
      base_url: Keyword.get(client, :auth0_base_url),
      client_id: Keyword.get(client, :client_id),
      client_secret: Keyword.get(client, :client_secret)
    }
  end
end
