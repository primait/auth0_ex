import Config

config :prima_auth0_ex,
  auth0_base_url: "https://tenant.eu.auth0.com"

config :prima_auth0_ex,
  clients: [
    {:example_client,
     auth0_base_url: "https://tenant.eu.auth0.com",
     client_id: "",
     client_secret: "",
     cache_enabled: true,
     cache_namespace: "my-service",
     cache_encryption_key: "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA=",
     redis_connection_uri: "redis://redis:6379",
     redis_ssl_enabled: false,
     redis_ssl_allow_wildcard_certificates: false}
  ]

config :prima_auth0_ex, :server,
  ignore_signature: false,
  audience: "some-audience",
  issuer: "https://tenant.eu.auth0.com/",
  first_jwks_fetch_sync: true

config :logger, :console, metadata: :all

config :logger, level: :info

import_config "#{config_env()}.exs"
