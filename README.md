# Auth0Ex

An easy to use library to authenticate machine-to-machine communications through Auth0.

Supports both retrieval of JWTs and their verification and validation.

## Installation

The package can be installed by adding `auth0_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:auth0_ex, git: "git@github.com:primait/auth0_ex.git", tag: "0.2.2"}
  ]
end
```

### Configuration

`auth0_ex` can be configured to be used for an API consumer, an API provider or both.

#### API Consumer

To configure the library for use from a client (ie. a service that needs to obtain tokens to access some API),
the following configuration is supported:

```elixir
config :auth0_ex,
  # Base url for Auth0 API
  auth0_base_url: "https://tenant.eu.auth0.com"

config :auth0_ex, :client,
  # Credentials on Auth0
  client_id: "",
  client_secret: "",
  # Enables cache on redis for tokens obtained from Auth0. Defaults to true.
  cache_enabled: true,
  # Namespace for tokens of this service on the shared cache. Should be unique per service (e.g., the service name)
  cache_namespace: "my-service",
  # AES 256 key used to encrypt tokens on the shared cache.
  # Can be generated via `:crypto.strong_rand_bytes(32) |> Base.encode64()`.
  cache_encryption_key: "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA=",
  redis_connection_uri: "redis://redis:6379"
```

**If the client will access APIs that perform validation of permissions, make sure that the API on Auth0 is configured to have both "Enable RBAC" and "Add Permissions in the Access Token" enabled.**
Otherwise, the JWTs generated by Auth0 may not include the necessary permissions claims.

#### API Provider

To configure the library for use from a server (ie. a service that exposes an API),
the following configuration is supported:

```elixir
config :auth0_ex,
  # Base url for Auth0 API
  auth0_base_url: "https://tenant.eu.auth0.com"

config :auth0_ex, :server,
  # Default audience used to verify tokens. Not necessary when audience is set explicitly on usage.
  audience: "audience",
  # Issuer used to verify tokens. Can be found at https://your-tenant.eu.auth0.com/.well-known/openid-configuration
  issuer: "https://tenant.eu.auth0.com/",
  # Whether to perform the first retrieval of JWKS synchronously. Defaults to true.
  first_jwks_fetch_sync: true,
  # When true, logs errors in validation of tokens, but it does not stop the request when the token is not valid.
  # Defaults to false.
  dry_run: false,
  # When true, only the claims of tokens are validated, but their signature is not verified.
  # This is useful for local development but should NEVER be enabled on production-like systems.
  # Defaults to false.
  ignore_signature: false
```

## Usage

### Obtaining tokens

Tokens for a given audience can be obtained as follows:

```elixir
{:ok, token} = Auth0Ex.token_for("target-audience")
```

Tokens are automatically refreshed when they expire and when the signing keys are revoked.
It is also possible to force the refresh of the token, both on the local instance and on the shared cache, as follows:

```elixir
{:ok, new_token} = Auth0Ex.refresh_token_for("target-audience")
```

A use-case for forcing the refresh of the token may be e.g., if new permissions are added to an application on Auth0, and we want to propagate this change without waiting for the natural expiration of tokens.

### Verifying tokens

Tokens can be verified and validated as follows:

```elixir
{:ok, claims} = Auth0Ex.verify_and_validate("my-token")
```

The audience and the required permissions can be explicitly specified:

```elixir
{:ok, claims} = Auth0Ex.verify_and_validate("my-token", "my-audience", ["required-permission1"])
```

For `Plug`-based applications, a plug to automate this process is available:

```elixir
plug Auth0Ex.Plug.VerifyAndValidateToken
```

This will return `401 Forbidden` to requests without a valid bearer token.

The plug supports the following options:

- `audience: "my-audience"` to explicitly set the expected audience. When not defined it defaults to the audience configured in `:auth0_ex, :server, :audience`;
- `required_permissions: ["p1", "p2"]` to forbid access to users who do not have all the required permissions;
- `dry_run` to allow access to the API when the token is not valid (mostly useful for testing purposes).

#### Validating permissions with Absinthe

In order to validate permissions in your Graphql API on a per-query/per-mutation basis, an option is to define an Absinthe middleware.
It is important to note that in the following example we will only validate permissions: the other validations and the verification of the signature will still need to be done elsewhere (eg., using the aforementioned plug).

First you'll need to pass the user's permissions to the Absinthe context.
This can be done with a Plug like this:

```elixir
defmodule ExampleWeb.Graphql.Context do
  def init(opts), do: opts

  def call(conn, _) do
    permissions =
      case Plug.Conn.get_req_header(conn, "authorization") do
        ["Bearer " <> token] -> Auth0Ex.Token.peek_permissions(token)
        _ -> []
      end

    Absinthe.Plug.put_options(conn, context: %{permissions: permissions})
  end
end
```

Then you can define an Absinthe Middleware that validates the required permissions, as follows:

```elixir
defmodule Example.Graphql.Middleware.RequirePermission do
  @behaviour Absinthe.Middleware

  def call(resolution, permission) do
    if permission in resolution.context[:permissions] do
      resolution
    else
      Absinthe.Resolution.put_result(resolution, {:error, "unauthorized"})
    end
  end
end
```

This middleware can then be used in your schema as follows:

```elixir
  field ... do
    middleware RequirePermission, "your-required-permission"
    resolve &Resolver.resolve_function/3
  end

```

## Development

The test suite can be executed as follows:

```bash
mix test
```

By default tests that integrate with Auth0 are excluded.
To run them, configure your auth0 credentials and audience in `config/test.exs` and run:

```bash
mix test --include external
```

Always run formatter, linter and dialyzer before pushing changes:

```bash
mix format
mix credo
mix dialyzer
```
