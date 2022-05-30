import Config

config :prima_auth0_ex,
  auth0_base_url: "https://tenant.eu.auth0.com"

config :prima_auth0_ex, :client,
  client_id: "",
  client_secret: "",
  cache_enabled: true,
  cache_namespace: "my-service",
  cache_encryption_key: "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA=",
  redis_connection_uri: "redis://localhost:6379"

config :prima_auth0_ex, :server,
  ignore_signature: false,
  audience: "some-audience",
  issuer: "https://tenant.eu.auth0.com/",
  first_jwks_fetch_sync: true

config :logger, :console, metadata: :all

config :logger, level: :info

import_config "#{config_env()}.exs"
