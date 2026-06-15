import Config
import Dotenvy

source!([
  ".env",
  System.get_env()
])



if env("PHX_SERVER", :boolean, false) do
  config :chat, ChatWeb.Endpoint, server: true
end

config :pushx,
  fcm_project_id: System.get_env("FCM_PROJECT_ID", "shlus-messenger")

config :chat, ChatWeb.Endpoint, http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  secret_key_base =
   env!("SECRET_KEY_BASE") ||
      raise "environment variable SECRET_KEY_BASE is missing"

  host = env("PHX_HOST", :string, "localhost")

  config :chat, ChatWeb.Endpoint,
    url: [host: host, port: 4000],
    secret_key_base: secret_key_base


  config :chat, Chat.Repo,
    username: env!("DB_USER"),
    password: env!("DB_PASSWORD"),
    database: env!("DB_NAME"),
    hostname: env!("DB_HOST"),
    port: env!("DB_PORT"),
    pool_size: 10,
    show_sensitive_data_on_connection_error: true

  config :ex_aws,
  access_key_id: env!("S3_ACCESS_KEY"),
  secret_access_key: env!("S3_SECRET_KEY"),
  region: "us-east-1"

  config :ex_aws, :s3,
    scheme: env!("S3_SCHEME"),
    host: env!("S3_HOST"),
    port: env!("S3_PORT")

  config :chat, :redis,
    url: env!("REDIS_URL")

else

  config :chat, Chat.Repo,
    username: env!("DEV_DB_USER"),
    password: env!("DEV_DB_PASSWORD"),
    database: env!("DEV_DB_NAME"),
    hostname: env!("DEV_DB_HOST"),
    port: env!("DEV_DB_PORT"),
    pool_size: 10,
    show_sensitive_data_on_connection_error: true

  config :ex_aws,
  access_key_id: env!("DEV_S3_ACCESS_KEY"),
  secret_access_key: env!("DEV_S3_SECRET_KEY"),
  region: "us-east-1"

  config :ex_aws, :s3,
    scheme: env!("DEV_S3_SCHEME"),
    host: env!("DEV_S3_HOST"),
    port: env!("DEV_S3_PORT")

  config :chat, :redis,
    url: env!("DEV_REDIS_URL")

end
