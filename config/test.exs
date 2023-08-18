import Config

config :prima_auth0_ex,
  clients: [],
  authorization_service: AuthorizationServiceMock,
  jwks_kids_fetcher: JwksKidsFetcherMock,
  refresh_strategy: RefreshStrategyMock,
  token_cache: TokenCacheMock,
  token_service: TokenServiceMock

config :prima_auth0_ex, :client,
  token_check_interval: :timer.seconds(1),
  signature_check_interval: :timer.seconds(1)

config :prima_auth0_ex, :test_client,
  auth0_base_url: "https://tenant.eu.auth0.com",
  client_id: "",
  client_secret: "",
  cache_enabled: true,
  cache_namespace: "test-client-namespace",
  cache_encryption_key: "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA=",
  redis_connection_uri: "redis://redis:6379",
  redis_ssl_enabled: false,
  redis_ssl_allow_wildcard_certificates: false,
  signature_check_interval: :timer.seconds(1),
  token_check_interval: :timer.seconds(1)

config :prima_auth0_ex, :other_test_client,
  auth0_base_url: "https://tenant.eu.auth0.com",
  client_id: "",
  client_secret: "",
  cache_enabled: true,
  cache_namespace: "other-test-client-namespace",
  cache_encryption_key: "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA=",
  redis_connection_uri: "redis://redis:6379",
  redis_ssl_enabled: false,
  redis_ssl_allow_wildcard_certificates: false,
  signature_check_interval: :timer.seconds(1),
  token_check_interval: :timer.seconds(1)

config :logger, level: :warn
