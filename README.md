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
  # time (in milliseconds) between pollings to check the freshness of tokens, and refresh them if necessary
  token_check_interval: :timer.minutes(1),
  # length of time window (in seconds) before token expiration when token refreshes can happen
  refresh_window_duration_seconds: 12 * 60 * 60,

config :auth0_ex, :cache,
  enabled: true,
  redis_connection_uri: "redis://localhost:6379",
  # namespace of cached tokens on shared cache (eg. redis). Should be unique per service.
  namespace: "my-service",
  # AES 256 key. Can be generated via `:crypto.strong_rand_bytes(32) |> Base.encode64()`.
  encryption_key: "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA="

config :auth0_ex, :auth0,
  # audience and issuer to validate when verifying tokens
  audience: "my-audience",
  issuer: "https://tenant.eu.auth0.com/",

  # credentials for auth0 used to obtain tokens
  client_id: "my-client-id",
  client_secret: "my-client-secret",
  base_url: "https://my-tenant.eu.auth0.com"

```

## Usage

### Obtaining tokens

Tokens for a given audience can be obtained as follows:

```elixir
{:ok, token} = Auth0Ex.token_for("target-audience")
```

### Verifying tokens

Tokens can be verified and validated as follows:

```elixir
{:ok, claims} = Auth0Ex.verify_and_validate("my-token")
```

For `Plug`-based applications, a plug to automate this process is available:

```elixir
plug Auth0Ex.Plug.VerifyAndValidateToken
```

This will return `401 Forbidden` to requests without a valid bearer token.
