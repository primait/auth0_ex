# Auth0Ex

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `auth0_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:auth0_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/auth0_ex](https://hexdocs.pm/auth0_ex).

### Configuration

This library supports the following configurations:

```elixir
config :auth0_ex,
  # time (in milliseconds) between checks of tokens. Default should be OK.
  token_check_interval: :timer.minutes(1),
  # time (in seconds) before token expiration when tokens can be refreshed. Default should be OK.
  refresh_window_duration_seconds: 12 * 60 * 60,
  # name of the Redix process. Default should be OK.
  redix_instance_name: :redix,
  # AES 256 key. Can be generated via `:crypto.strong_rand_bytes(32) |> Base.encode64()`.
  token_encryption_key: "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA=",
  # namespace of cached tokens on shared cache (eg. redis). Should be unique per service.
  cache_namespace: "my-service"

# Auth0 credentials
config :auth0_ex, :auth0,
  client_id: "auth0-client-id",
  client_secret: "auth0-client-secret",
  base_url: "https://my-domain.eu.auth0.com"
```