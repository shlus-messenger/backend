defmodule Chat.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do

    :ok = run_migrations()

    children = [

      Chat.Repo,
      {Registry, keys: :unique, name: Chat.RoomRegistry},
      {DynamicSupervisor, name: Chat.RoomSupervisor, strategy: :one_for_one},
      {Phoenix.PubSub, name: Chat.PubSub},
      Chat.Clients.Redis,
      ChatWeb.Presence,
      ChatWeb.Endpoint

    ]

    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    {:ok, pid}

  end

  defp run_migrations do
    if Application.get_env(:chat, :run_migrations, true) do
      IO.puts("Running migrations...")
      _ = Ecto.Migrator.with_repo(Chat.Repo, &Ecto.Migrator.run(&1, :up, all: true))
      :ok
    else
      :ok
    end
  end

  @impl true
  def config_change(changed, _new, removed) do

    ChatWeb.Endpoint.config_change(changed, removed)
    :ok

  end


end
