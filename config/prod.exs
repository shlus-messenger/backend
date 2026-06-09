import Config

if System.get_env("PHX_SERVER") do
  config :chat, ChatWeb.Endpoint, server: true
end

config :chat, ChatWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4000"))]

config :chat, Chat.Repo,
  username: System.get_env("DB_USER"),
  password: System.get_env("DB_PASSWORD"),
  database: System.get_env("DB_NAME"),
  hostname: System.get_env("DB_HOST"),
  port: System.get_env("DB_PORT"),
  pool_size: 10

config :logger, level: :info
