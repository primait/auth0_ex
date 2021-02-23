use Mix.Config

if Mix.env() == :test do
  config :auth0_ex,
    client_id: "",
    client_secret: "",
    default_audience: "",
    domain: ""
end
