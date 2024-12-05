import Config

config :prima_auth0_ex, :redis, enabled: false

config :logger, level: :debug

config :ex_aws,
  access_key_id: "ABCD",
  secret_access_key: "secret"

config :ex_aws, :dynamodb,
  scheme: "http://",
  host: "dynamodb",
  port: 4566,
  region: "us-east-1"
