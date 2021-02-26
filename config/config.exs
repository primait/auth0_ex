use Mix.Config

config :auth0_ex,
  authorization_service: Auth0Ex.Consumer.Auth0AuthorizationService,
  token_cache: TokenCacheMock

if Mix.env() == :test do
  config :auth0_ex,
    authorization_service: AuthorizationServiceMock,
    token_cache: TokenCacheMock
end

if Mix.env() in [:dev, :test] do
  config :auth0_ex, :auth0,
    client_id: "",
    client_secret: "",
    default_audience: "",
    base_url: "https://dallagi.eu.auth0.com"
end
