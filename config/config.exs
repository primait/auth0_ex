use Mix.Config

config :auth0_ex,
  auth0_base_url: "https://dallagi.eu.auth0.com"

config :auth0_ex, :cache,
  enabled: true,
  redis_connection_uri: "redis://redis:6379",
  namespace: "my-service",
  encryption_key: "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA="

config :auth0_ex, :client,
  token_check_interval: :timer.minutes(1),
  min_token_duration: 0.5,
  max_token_duration: 0.75,
  client_id: "",
  client_secret: ""

config :auth0_ex, :server,
  audience: "",
  issuer: "https://tenant.eu.auth0.com/",
  first_jwks_fetch_sync: true

import_config "#{Mix.env()}.exs"
