use Mix.Config

if Mix.env() in [:dev, :test] do
  config :auth0_ex,
    client_id: "",
    client_secret: "",
    default_audience: "",
    domain: ""
end
