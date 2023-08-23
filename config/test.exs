import Config

config :prima_auth0_ex,
  authorization_service: AuthorizationServiceMock,
  jwks_kids_fetcher: JwksKidsFetcherMock,
  refresh_strategy: RefreshStrategyMock,
  token_cache: TokenCacheMock,
  token_service: TokenServiceMock

config :prima_auth0_ex, :redis,
  enabled: true,
  encryption_key: "uhOrqKvUi9gHnmwr60P2E1hiCSD2dtXK1i6dqkU4RTA=",
  connection_uri: "redis://redis:6379",
  ssl_enabled: false,
  ssl_allow_wildcard_certificates: false

config :prima_auth0_ex, :clients,
  test_client: [
    auth0_base_url: "https://your-auth0-client.com",
    client_id: "",
    client_secret: "",
    cache_namespace: "test-client-namespace",
    signature_check_interval: :timer.seconds(1),
    token_check_interval: :timer.seconds(1)
  ]

config :prima_auth0_ex, :clients,
  other_test_client: [
    auth0_base_url: "https://your-auth0-client.com",
    client_id: "",
    client_secret: "",
    cache_namespace: "other-test-client-namespace",
    signature_check_interval: :timer.seconds(1),
    token_check_interval: :timer.seconds(1)
  ]

config :logger, level: :warn
