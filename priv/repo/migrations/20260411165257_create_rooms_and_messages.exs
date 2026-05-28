defmodule Chat.Repo.Migrations.CreateRoomsAndMessages do
  use Ecto.Migration

  def change do

    create table(:rooms, primary_key: false) do

      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :owner_id, :uuid, null: false
      add :logo_url, :text, null: true
      add :accessability, :text, null: true
      add :type, :text, null: false
      add :members, {:array, :text}, null: false
      timestamps()

    end

    create table(:users, primary_key: false) do

      add :user_id, :uuid, primary_ley: true
      add :name, :text, null: false
      add :avatar_url, :text, null: true
      add :status, :text, null: false
      add :last_seen_at, :utc_datetime_usec, null: true

    end

    create table(:users_settings, primary_key: false) do

      add :user_id, :uuid, primary_key: true
      add :theme, :string, null: true
      add :hide_last_seen_at, :boolean, null: true


    end

    create table(:messages, primary_key: false) do

      add :id, :uuid
      add :room_id, references(:rooms, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, :uuid, null: false
      add :user_name, :text, null: false
      add :body, :text, null: false
      add :views, :uuid, null: true
      add :reply_to, :uuid, null: true
      timestamps()

    end

    create table(:message_views, primary_key: true) do

      add :message_id, :uuid, null: false
      add :user_id, :uuid, null: false
      add :viewed_at, :utc_datetime_usec, null: false

    end

    create table(:message_reactions, primary_key: true) do

      add :message_id, :uuid, null: false
      add :user_id, :uuid, null: false
      add :reacted_at, :utc_datetime_usec, null: false
      add :reaction, :text, null: false

    end

    create index(:messages, [:room_id])
    create index(:messages, [:inserted_at])

  end
end
