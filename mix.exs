defmodule PrimaAuth0Ex.MixProject do
  use Mix.Project

  @source_url "https://github.com/primait/auth0_ex"
  @version "0.3.1"

  def project do
    [
      app: :prima_auth0_ex,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        plt_add_deps: :transitive,
        ignore_warnings: ".dialyzerignore",
        list_unused_filters: true
      ],
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {PrimaAuth0Ex.Application, []},
      extra_applications: [:crypto, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:absinthe, "~> 1.6", optional: true},
      {:absinthe_plug, "~> 1.5", optional: true},
      {:jason, "~> 1.0"},
      {:joken, "~> 2.4"},
      {:joken_jwks, "~> 1.4"},
      {:plug, "~> 1.10", optional: true},
      {:redix, "~> 0.9 or ~> 1.0"},
      {:telepoison, "~> 1.0"},
      {:timex, "~> 3.6"},
      {:statix, github: "primait/statix", branch: "feature/switch_from_config"}
    ] ++ dev_deps()
  end

  defp dev_deps do
    [
      {:bypass, "~> 2.1.0", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.25.3", only: :dev, runtime: false},
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
      ],
      keygen: [
        "run --no-start -e ':crypto.strong_rand_bytes(32) |> Base.encode64() |> IO.puts()'"
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp package do
    [
      description: "An easy to use library to authenticate machine-to-machine communications through Auth0.",
      name: "prima_auth0_ex",
      maintainers: ["Prima"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
