defmodule PrimaAuth0Ex.ConfigHelper do
  @moduledoc nil

  def fetch_env_with_default(app, key, default) do
    case Application.fetch_env(app, key) do
      {:ok, value} -> value
      :error -> default
    end
  end
end
