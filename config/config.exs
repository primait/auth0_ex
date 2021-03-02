use Mix.Config

config :auth0_ex,
  authorization_service: Auth0Ex.Consumer.Auth0AuthorizationService,
  refresh_strategy: RefreshStrategyMock,
  token_cache: TokenCacheMock,
  token_check_interval: :timer.minutes(1)

if Mix.env() == :test do
  config :auth0_ex,
    authorization_service: AuthorizationServiceMock,
    refresh_strategy: RefreshStrategyMock,
    token_cache: TokenCacheMock,
    token_check_interval: :timer.seconds(1)
end

if Mix.env() in [:dev, :test] do
  config :auth0_ex, :auth0,
    client_id: "",
    client_secret: "",
    default_audience: "",
    base_url: "https://dallagi.eu.auth0.com"
end
