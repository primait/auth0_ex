import Config

config :prima_auth0_ex,
  authorization_service: AuthorizationServiceMock,
  jwks_kids_fetcher: JwksKidsFetcherMock,
  refresh_strategy: RefreshStrategyMock,
  token_cache: TokenCacheMock,
  token_service: TokenServiceMock

config :prima_auth0_ex, :server,
  auth0_base_url: "server",
  ignore_signature: false,
  audience: "server",
  issuer: "server",
  first_jwks_fetch_sync: true

config :prima_auth0_ex, :redis,
  enabled: true,
  encryption_key: "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA=",
  connection_uri: "redis://redis:6379",
  ssl_enabled: false,
  ssl_allow_wildcard_certificates: false

config :prima_auth0_ex, :clients,
  default_client: [
    auth0_base_url: "default",
    client_id: "default",
    client_secret: "default",
    cache_namespace: "default",
    token_check_interval: :timer.seconds(1),
    signature_check_interval: :timer.seconds(1)
  ]

config :prima_auth0_ex, :clients,
  test_client: [
    auth0_base_url: "test",
    client_id: "test",
    client_secret: "test",
    cache_namespace: "test",
    signature_check_interval: :timer.seconds(1),
    token_check_interval: :timer.seconds(1)
  ]

config :logger, level: :warn
