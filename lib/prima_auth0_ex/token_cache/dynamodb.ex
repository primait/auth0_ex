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

  def from_token_info(key, %TokenInfo{expires_at: expires_at, issued_at: issued_at, kid: kid, jwt: jwt}) do
    %__MODULE__{
      key: key,
      expires_at: expires_at,
      issued_at: issued_at,
      kid: kid,
      jwt: jwt
    }
  end

  def to_token_info(%__MODULE__{issued_at: issued_at, expires_at: expires_at, jwt: jwt, kid: kid}) do
    %TokenInfo{
      jwt: jwt,
      kid: kid,
      expires_at: expires_at,
      issued_at: issued_at
    }
  end
end

defmodule PrimaAuth0Ex.TokenCache.DynamoDB do
  alias PrimaAuth0Ex.TokenCache.DynamoDB.StoredToken
  alias PrimaAuth0Ex.TokenCache
  alias PrimaAuth0Ex.Config
  alias PrimaAuth0Ex.TokenProvider.TokenInfo
  alias ExAws.Dynamo

  @behaviour TokenCache

  @impl TokenCache
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start, []},
      restart: :transient
    }
  end

  def start do
    if create_table?() do
      create_update_table()
    end

    :ignore
  end

  @impl TokenCache
  # Dialyzer complains about the %{:ok, %{}} pattern never matching
  # This is incorrect, most likely an issue with ExAws types.
  # We do have a unit case that covers this
  @dialyzer {:nowarn_function, get_token_for: 2}
  def get_token_for(client \\ :default_client, audience) do
    with request <- Dynamo.get_item(table_name(), %{key: key(client, audience)}, consistent_read: false),
         {:ok, res} when res != %{} <- ExAws.request(request),
         %StoredToken{} = stored_token <-
           Dynamo.decode_item(res, as: StoredToken) do
      {:ok, StoredToken.to_token_info(stored_token)}
    else
      {:ok, %{}} -> {:ok, nil}
      {:error, error} -> {:error, error}
    end
  end

  @impl TokenCache
  def set_token_for(
        client \\ :default_client,
        audience,
        %TokenInfo{} = token_info
      ) do
    stored_token = StoredToken.from_token_info(key(client, audience), token_info)

    case Dynamo.put_item(table_name(), stored_token) |> ExAws.request() do
      {:ok, _} -> :ok
      {:error, err} -> {:error, err}
    end
  end

  # More ExAws typing issues
  @dialyzer {:nowarn_function, create_update_table: 0}
  def create_update_table() do
    case Dynamo.describe_table(table_name()) |> ExAws.request() do
      {:error, _} ->
        Dynamo.create_table(table_name(), "key", %{key: :string}, 4, 1)
        |> ExAws.request!()

      _ ->
        nil
    end

    Dynamo.update_time_to_live(table_name(), "expires_at", true)
    |> ExAws.request!()

    nil
  end

  def delete_table() do
    Dynamo.delete_table(table_name())
    |> ExAws.request()
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
