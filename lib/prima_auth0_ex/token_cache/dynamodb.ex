defmodule PrimaAuth0Ex.TokenCache.DynamoDB.StoredToken do
  alias PrimaAuth0Ex.TokenProvider.TokenInfo
  @derive [ExAws.Dynamo.Encodable]
  defstruct [:key, :jwt, :issued_at, :expires_at, :kid]

  @type t :: %__MODULE__{
          key: String.t(),
          jwt: String.t(),
          issued_at: non_neg_integer(),
          expires_at: non_neg_integer(),
          kid: String.t()
        }
end

defmodule PrimaAuth0Ex.TokenCache.DynamoDB do
  alias PrimaAuth0Ex.TokenCache.DynamoDB.StoredToken
  alias PrimaAuth0Ex.TokenCache
  alias PrimaAuth0Ex.Config
  alias PrimaAuth0Ex.TokenProvider.TokenInfo
  alias ExAws.Dynamo

  @behaviour TokenCache

  @impl TokenCache
  def child_spec(_),
    do: %{
      id: __MODULE__,
      start: {__MODULE__, :start, []},
      restart: :transient
    }

  def start do
    if create_table?() do
      create_update_table()
    end

    :ignore
  end

  @impl TokenCache
  def get_token_for(client \\ :default_client, audience) do
    with request <- Dynamo.get_item(table_name(), %{key: key(client, audience)}, consistent_read: false),
         {:ok, res} when res != %{} <- ExAws.request(request),
         %StoredToken{issued_at: issued_at, expires_at: expires_at, jwt: jwt, kid: kid} <-
           Dynamo.decode_item(res, as: StoredToken) do
      {:ok,
       %TokenInfo{
         jwt: jwt,
         kid: kid,
         expires_at: expires_at,
         issued_at: issued_at
       }}
    else
      {:ok, %{}} -> {:ok, nil}
      {:error, error} -> {:error, error}
    end
  end

  @impl TokenCache
  def set_token_for(
        client \\ :default_client,
        audience,
        %TokenInfo{expires_at: expires_at, issued_at: issued_at, kid: kid, jwt: jwt} = token_info
      ) do
    stored_token = %StoredToken{
      key: key(client, audience),
      expires_at: expires_at,
      issued_at: issued_at,
      kid: kid,
      jwt: jwt
    }

    case Dynamo.put_item(table_name(), stored_token) |> ExAws.request() do
      {:ok, _} -> :ok
      {:error, err} -> {:error, err}
    end
  end

  def create_update_table() do
    if {:error, _} = Dynamo.describe_table(table_name()) |> ExAws.request() do
      Dynamo.create_table(table_name(), "key", %{key: :string}, 4, 1)
      |> ExAws.request!()
    end

    Dynamo.update_time_to_live(table_name(), "expires_at", true)
    |> ExAws.request!()
  end

  def delete_table() do
    Dynamo.delete_table(table_name())
    |> ExAws.request!()
  end

  def create_table? do
    Config.dynamodb(:create_table, true)
  end

  defp table_name do
    Config.dynamodb!(:table_name)
  end

  def key(client \\ :default_client, audience) do
    "#{client}:#{audience}"
  end
end
