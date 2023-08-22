import Config

# Default client, for backwards compatibility
config :prima_auth0_ex, :client,
  auth0_base_url: "https://tenant.eu.auth0.com",
  client_id: "",
  client_secret: "",
  cache_namespace: "my-service"

config :prima_auth0_ex, :redis,
  enabled: true,
  encryption_key: "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA=",
  connection_uri: "redis://redis:6379",
  ssl_enabled: false,
  ssl_allow_wildcard_certificates: false

config :prima_auth0_ex, :server,
  ignore_signature: false,
  audience: "some-audience",
  issuer: "https://tenant.eu.auth0.com/",
  first_jwks_fetch_sync: true

config :logger, :console, metadata: :all

config :logger, level: :info

import_config "#{config_env()}.exs"
