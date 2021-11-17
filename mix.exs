defmodule Auth0Ex.MixProject do
  use Mix.Project

  def project do
    [
      app: :auth0_ex,
      version: "0.2.5",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
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
      {:joken, "~> 2.4.0"},
      {:joken_jwks, "~> 1.4"},
      {:plug, "~> 1.10"},
      {:redix, "~> 0.9 or ~> 1.0"},
      {:telepoison, "~> 1.0.0-rc.4"},
      {:timex, "~> 3.6"}
    ] ++ dev_deps()
  end

  defp dev_deps do
    [
      {:bypass, "~> 2.1.0", only: :test},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:hammox, "~> 0.5", only: :test},
      {:stream_data, "~> 0.5", only: :test}
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted",
        "credo -a --strict",
        "dialyzer"
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
