defmodule PrimaAuth0Ex.TokenCache.NoopCache do
  alias PrimaAuth0Ex.TokenCache

  @moduledoc """
  Implementation of `PrimaAuth0Ex.TokenCache` that doesn't persist tokens at all.
  """
  @behaviour TokenCache

  @impl TokenCache
  def get_token_for(_, _), do: {:ok, nil}

  @impl TokenCache
  def set_token_for(_, _, _), do: :ok

  def children(), do: []
end
