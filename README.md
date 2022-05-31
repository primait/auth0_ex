# prima_auth0_ex

[![Module Version](https://img.shields.io/hexpm/v/prima_auth0_ex.svg)](https://hex.pm/packages/prima_auth0_ex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/prima_auth0_ex/)
[![Total Download](https://img.shields.io/hexpm/dt/prima_auth0_ex.svg)](https://hex.pm/packages/prima_auth0_ex)
[![License](https://img.shields.io/hexpm/l/prima_auth0_ex.svg)](https://github.com/primait/auth0_ex/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/primait/auth0_ex.svg)](https://github.com/primait/auth0_ex/commits/master)

An easy to use library to authenticate machine-to-machine communications through Auth0.

Supports both retrieval of JWTs and their verification and validation.

## Table of contents

- [Installation](#installation)
- [Configuration](#configuration)
  - [I am a DevOps, what do I have to do?](#i-am-a-devops-what-do-i-have-to-do)
- [Usage](#usage)
- [Development](#development)

## Installation

The package can be installed by adding `prima_auth0_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:prima_auth0_ex, "~> 0.3.0"}
  ]
end
```

## Configuration

`prima_auth0_ex` can be configured to be used for an API consumer, an API provider or both.

### API Consumer

To configure the library for use from a client (ie. a service that needs to obtain tokens to access some API),
the following configuration is supported:

```elixir
config :prima_auth0_ex,
  # Base url for Auth0 API
  auth0_base_url: "https://tenant.eu.auth0.com"

config :prima_auth0_ex, :client,
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

A visualization of the logic behind the `TokenProvider` is available [here](client_flow.jpg).

### API Provider

To configure the library for use from a server (ie. a service that exposes an API),
the following configuration is supported:

```elixir
config :prima_auth0_ex,
  # Base url for Auth0 API
  auth0_base_url: "https://tenant.eu.auth0.com"

config :prima_auth0_ex, :server,
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
  ignore_signature: false,
  # Level used to log requests where the authorization header is missing. 
  missing_auth_header_log_level: :warn
```

### I am a DevOps, what do I have to do?

As a DevOps someone is probably going to ask you to generate a `cache_encryption_key`, which can be generated either running `mix keygen` or using the following snippet:

```elixir
:crypto.strong_rand_bytes(32) |> Base.encode64()
```

> :warning: **The token needs to be 32 bytes long AND base64 encoded**, failing to do so will result in tokens not getting cached on Redis. :warning:

## Usage

### Obtaining tokens

Tokens for a given audience can be obtained as follows:

```elixir
{:ok, token} = PrimaAuth0Ex.token_for("target-audience")
```

Tokens are automatically refreshed when they expire and when the signing keys are revoked.
It is also possible to force the refresh of the token, both on the local instance and on the shared cache, as follows:

```elixir
{:ok, new_token} = PrimaAuth0Ex.refresh_token_for("target-audience")
```

A use-case for forcing the refresh of the token may be e.g., if new permissions are added to an application on Auth0, and we want to propagate this change without waiting for the natural expiration of tokens.

### Verifying tokens

Tokens can be verified and validated as follows:

```elixir
{:ok, claims} = PrimaAuth0Ex.verify_and_validate("my-token")
```

The audience and the required permissions can be explicitly specified:

```elixir
{:ok, claims} = PrimaAuth0Ex.verify_and_validate("my-token", "my-audience", ["required-permission1"])
```

For `Plug`-based applications, a plug to automate this process is available:

```elixir
plug PrimaAuth0Ex.Plug.VerifyAndValidateToken
```

This will return `401 Forbidden` to requests without a valid bearer token.

The plug supports the following options:

- `audience: "my-audience"` to explicitly set the expected audience. When not defined it defaults to the audience configured in `:prima_auth0_ex, :server, :audience`;
- `required_permissions: ["p1", "p2"]` to forbid access to users who do not have all the required permissions;
- `dry_run` to allow access to the API when the token is not valid (mostly useful for testing purposes).

#### Validating permissions with Absinthe

In order to validate permissions in your Graphql API on a per-query/per-mutation basis, an option is to define an Absinthe middleware. To this end you can use the [PrimaAuth0Ex.Absinthe.RequirePermissions](lib/prima_auth0_ex/absinthe/require_permissions.ex) included with the library or build your own.

This middleware has a companion plug: [PrimaAuth0Ex.Absinthe.CreateSecurityContext](lib/prima_auth0_ex/absinthe/create_security_context.ex), which can be used to pass the user's permissions to the Absinthe context.

It is important to note that the middleware will only validate permissions: other validations and the verification of the signature will still need to be done elsewhere (e.g. using the aforementioned plug).

The middleware can be used in your schema as follows:

```elixir
field ... do
  middleware RequirePermissions, ["your-required-permission"]
  resolve &Resolver.resolve_function/3
```

### Metrics

`prima_auth0_ex` uses `:telemetry` to [emit two events](/lib/prima_auth0_ex/token_provider/auth0_authorization_service.ex#L56)

- `[:prima_auth0_ex, :retrieve_token, :success]`
- `[:prima_auth0_ex, :retrieve_token, :failure]`

which represent a successful or failed attempt to fetch a new JWT from Auth0.

If you want to leverage them you can

- register a custom handler (see [here](https://hexdocs.pm/telemetry/readme.html)) or
- configure the [pre-defined handler](/lib/prima_auth0_ex/telemetry.ex)

The pre-defined handler tries to be as agnostic as possible from the underlying reporter and it can be configured by setting the following

```elixir
config :prima_auth0_ex, telemetry_reporter: TelemetryReporter
```

At startup the library will check if a reporter has been configured and then it will attach it as an handler.

In order to work, the reporter needs to have an `increment` method like in Statix or Instruments, and it will then increment one of two counters: `retrieve_token:success` or `retrieve_token:failure`. Each counter will be tagged by `audience`.

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
mix check
```
