use Mix.Config

config :auth0_ex,
  authorization_service: Auth0Ex.Consumer.Auth0AuthorizationService,
  refresh_strategy: Auth0Ex.Consumer.ProbabilisticRefreshStrategy,
  token_cache: TokenCacheMock,
  token_service: Auth0Ex.Consumer.CachedTokenService,
  token_check_interval: :timer.minutes(1),
  refresh_window_duration_seconds: 12 * 60 * 60

config :auth0_ex, :auth0,
  client_id: "",
  client_secret: "",
  default_audience: "",
  base_url: "https://dallagi.eu.auth0.com"

import_config "#{Mix.env()}.exs"
