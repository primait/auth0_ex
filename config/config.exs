import Config

# Default client, for backwards compatibility
config :prima_auth0_ex, :clients,
  default_client: [
    auth0_base_url: "http://localauth0:3000",
    client_id: "client_id",
    client_secret: "client_secret",
    cache_namespace: "service_name:client_name",
    token_check_interval: :timer.seconds(1),
    signature_check_interval: :timer.seconds(1)
  ]

config :prima_auth0_ex, token_cache: EncryptedRedisTokenCache

config :prima_auth0_ex, :redis,
  encryption_key: "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA=",
  connection_uri: "redis://redis:6379",
  ssl_enabled: false,
  ssl_allow_wildcard_certificates: false

config :prima_auth0_ex, :server,
  auth0_base_url: "http://localauth0:3000",
  ignore_signature: false,
  audience: "some-audience",
  issuer: "https://your-auth0-tenant.com",
  first_jwks_fetch_sync: true

config :logger, :console, metadata: :all

config :logger, level: :info

import_config "#{config_env()}.exs"
