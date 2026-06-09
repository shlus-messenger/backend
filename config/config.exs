import Config

config :chat,
  generators: [timestamp_type: :utc_datetime],
  ecto_repos: [Chat.Repo]

config :chat, ChatWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [json: ChatWeb.ErrorJSON], layout: false],
  pubsub_server: Chat.PubSub,
  live_view: [signing_salt: "lwti4PfN"]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
