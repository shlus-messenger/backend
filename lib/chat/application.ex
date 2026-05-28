defmodule Chat.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do

    :ok = run_migrations()

    children = [

      Chat.Repo,
      {Registry, keys: :unique, name: Chat.RoomRegistry},
      {Phoenix.PubSub, name: Chat.PubSub},
      ChatWeb.Presence,
      ChatWeb.Endpoint

    ]

    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    restore_rooms_from_db()

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

  defp restore_rooms_from_db do

    rooms = Chat.list_rooms()

    for room <- rooms do

      case Chat.Room.start_link(room.name, room.owner_id, room.logo_url, room.accessability, room.type, room.id) do

        {:ok, _pid, room_id} ->
          IO.puts("✅ Restored room: #{room.name} (ID: #{room_id})")
        {:error, {:already_started, _pid}} ->
          IO.puts("⚠️ Room already running: #{room.name}")
        {:error, error} ->
          IO.puts("❌ Failed to restore room #{room.name}: #{inspect(error)}")

      end

    end

  end

  @impl true
  def config_change(changed, _new, removed) do

    ChatWeb.Endpoint.config_change(changed, removed)
    :ok

  end


end
