import Config

config :chat, Chat.Repo,
  username: "chat_admin",
  password: "f3245454h5b34hvfgj325v23",
  database: "deve_chat",
  hostname: "localhost",
  port: 5433,
  pool_size: 10

config :chat, ChatWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "s1OXT5L5Y74CCOAd6Gmd9WNZW70A56alwvqUgIxp9fu9b09qcSa+5qq2POGWGDYo",
  server: false

config :chat, Chat.Mailer, adapter: Swoosh.Adapters.Test

config :swoosh, :api_client, false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :phoenix,
  sort_verified_routes_query_params: true
