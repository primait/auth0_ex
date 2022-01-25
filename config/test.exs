import Config

config :prima_auth0_ex,
  authorization_service: AuthorizationServiceMock,
  jwks_kids_fetcher: JwksKidsFetcherMock,
  refresh_strategy: RefreshStrategyMock,
  token_cache: TokenCacheMock,
  token_service: TokenServiceMock

config :prima_auth0_ex, :client,
  cache_enabled: true,
  token_check_interval: :timer.seconds(1),
  signature_check_interval: :timer.seconds(1)

config :logger, level: :warn
