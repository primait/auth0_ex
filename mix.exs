defmodule Auth0Ex.MixProject do
  use Mix.Project

  def project do
    [
      app: :auth0_ex,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Auth0Ex.Application, []},
      extra_applications: [:crypto, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bypass, "~> 2.1.0"},
      {:jason, "~> 1.2.2"},
      {:joken, "~> 2.3.0"},
      {:redix, "~> 1.0.0"},
      {:telepoison, "~> 0.1.1"}
    ] ++ dev_deps()
  end

  defp dev_deps do
    [
      {:hammox, "~> 0.4", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
