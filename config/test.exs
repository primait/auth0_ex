use Mix.Config

config :auth0_ex,
  authorization_service: AuthorizationServiceMock,
  refresh_strategy: RefreshStrategyMock,
  token_cache: TokenCacheMock,
  token_service: TokenServiceMock

config :auth0_ex, :client,
  cache_enabled: true,
  token_check_interval: :timer.seconds(1)
