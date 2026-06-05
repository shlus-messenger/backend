import Config
import Dotenvy

if System.get_env("PHX_SERVER") do
  config :chat, ChatWeb.Endpoint, server: true
end

config :chat, ChatWeb.Endpoint, http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4000"))]

source!([
  ".env",
  ".#{config_env()}.env",
  System.get_env()
])

config :ex_aws,
  access_key_id: env!("S3_ACCESS_KEY"),
  secret_access_key: env!("S3_SECRET_KEY"),
  region: "us-east-1"

config :ex_aws, :s3,
  scheme: env!("S3_SCHEME"),
  host: env!("S3_HOST"),
  port: env!("S3_PORT")


if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "environment variable SECRET_KEY_BASE is missing"

  host = System.get_env("PHX_HOST") || "localhost"

  config :chat, ChatWeb.Endpoint,
    url: [host: host, port: 4000],
    secret_key_base: secret_key_base


  config :chat, Chat.Repo,
    username: System.get_env("DB_USER"),
    password: System.get_env("DB_PASSWORD"),
    database: System.get_env("DB_NAME"),
    hostname: System.get_env("DB_HOST"),
    port: System.get_env("DB_PORT"),
    pool_size: 10,
    show_sensitive_data_on_connection_error: true
end
