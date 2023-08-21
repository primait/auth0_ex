ExUnit.configure(exclude: :external)
ExUnit.start()

defmodule PrimaAuth0Ex.TestHelper do
  import ExUnit.Callbacks

  @spec set_redis_env(term(), term(), Keyword.t()) :: :ok
  def set_redis_env(key, value, opts \\ []) do
    reset? = Keyword.get(opts, :reset?, true)
    do_set_env(:redis, key, value, reset?)
  end

  @spec set_client_env(atom(), term(), term(), Keyword.t()) :: :ok
  def set_client_env(client, key, value, opts \\ []) do
    reset? = Keyword.get(opts, :reset?, true)
    do_set_env(client, key, value, reset?)
  end

  defp do_set_env(config, key, value, false) do
    Application.get_env(:prima_auth0_ex, config, [])
    |> Keyword.put(key, value)
    |> then(&Application.put_env(:prima_auth0_ex, config, &1))
  end

  defp do_set_env(config, key, value, true) do
    previous_value = Application.get_env(:prima_auth0_ex, config, [])
    updated_value = Keyword.put(previous_value, key, value)
    Application.put_env(:prima_auth0_ex, config, updated_value)

    on_exit(fn ->
      Application.put_env(:prima_auth0_ex, config, previous_value)
    end)
  end
end
