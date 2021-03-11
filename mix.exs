defmodule Auth0Ex.MixProject do
  use Mix.Project

  def project do
    [
      app: :auth0_ex,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        plt_add_deps: :transitive,
        ignore_warnings: ".dialyzerignore",
        list_unused_filters: true
      ]
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
      {:jason, "~> 1.2.2"},
      {:joken, "~> 2.3.0"},
      {:joken_jwks, "~> 1.1.0"},
      {:plug, "~> 1.11"},
      {:redix, "~> 1.0.0"},
      {:telepoison, "~> 0.1.1"}
    ] ++ dev_deps()
  end

  defp dev_deps do
    [
      {:bypass, "~> 2.1.0", only: :test},
      {:dialyxir, "1.0.0", only: [:dev], runtime: false},
      {:hammox, "~> 0.4", only: :test},
      {:timex, "~> 3.6", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
