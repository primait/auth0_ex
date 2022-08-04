ExUnit.configure(exclude: :external)
ExUnit.start()

defmodule PrimaAuth0Ex.TestHelper do
  import ExUnit.Callbacks

  @spec set_client_env(term(), term(), Keyword.t()) :: :ok
  def set_client_env(key, value, opts \\ []) do
    reset? = Keyword.get(opts, :reset?, true)
    do_set_client_env(key, value, reset?)
  end

  defp do_set_client_env(key, value, false) do
    Application.get_env(:prima_auth0_ex, :client, [])
    |> Keyword.put(key, value)
    |> then(&Application.put_env(:prima_auth0_ex, :client, &1))
  end

  defp do_set_client_env(key, value, true) do
    previous_value = Application.get_env(:prima_auth0_ex, :client, [])
    updated_value = Keyword.put(previous_value, key, value)
    Application.put_env(:prima_auth0_ex, :client, updated_value)

    on_exit(fn ->
      Application.put_env(:prima_auth0_ex, :client, previous_value)
    end)
  end
end
