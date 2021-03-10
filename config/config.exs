use Mix.Config

config :auth0_ex,
  authorization_service: Auth0Ex.TokenProvider.Auth0AuthorizationService,
  refresh_strategy: Auth0Ex.TokenProvider.ProbabilisticRefreshStrategy,
  token_cache: Auth0Ex.TokenProvider.EncryptedRedisTokenCache,
  token_service: Auth0Ex.TokenProvider.CachedTokenService,
  auth0_base_url: "https://dallagi.eu.auth0.com"

config :auth0_ex, :cache,
  enabled: true,
  redis_connection_uri: "redis://localhost:6379",
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
  issuer: "https://tenant.eu.auth0.com/"

import_config "#{Mix.env()}.exs"
