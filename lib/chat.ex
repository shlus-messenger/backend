defmodule Chat do

  alias Chat.Repo
  alias Chat.Schemas.Room
  alias Chat.Schemas.User
  alias Chat.Schemas.Message
  import Ecto.Query

  def create_room(attrs) do

    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()

  end

  def get_room!(id) do

    Repo.get!(Room, id)

  end

  def list_rooms do

    Repo.all(Room)

  end

  def get_all_public_rooms(amount) do

    query = from r in Chat.Schemas.Room,
      where: r.accessability == "public",
      limit: ^amount,
      select: %{
        id: r.id,
        name: r.room_name,
        type: r.room_type,
        logo_url: r.logo_url,
        last_message: fragment(
          "(SELECT body FROM messages WHERE room_id = ? ORDER BY inserted_at DESC LIMIT 1)",
          r.id
        ),
        last_message_at: fragment(
          "(SELECT inserted_at FROM messages WHERE room_id = ? ORDER BY inserted_at DESC LIMIT 1)",
          r.id
        ),
        last_message_user_name: fragment(
          "(SELECT user_name FROM messages WHERE room_id = ? ORDER BY inserted_at DESC LIMIT 1)",
          r.id
        )
      }

    Repo.all(query)

  end

  def get_rooms_by_user_id(user_id) do
    query = from u in Chat.Schemas.User,
      join: r in Chat.Schemas.Room,
      on: u.room_id == r.id,
      where: u.user_id == ^user_id,
      select: %{
        id: r.id,
        name: r.room_name,
        type: r.room_type,
        logo_url: r.logo_url,
        last_message: fragment(
          "(SELECT body FROM messages WHERE room_id = ? ORDER BY inserted_at DESC LIMIT 1)",
          r.id
        ),
        last_message_at: fragment(
          "(SELECT inserted_at FROM messages WHERE room_id = ? ORDER BY inserted_at DESC LIMIT 1)",
          r.id
        ),
        last_message_user_name: fragment(
          "(SELECT user_name FROM messages WHERE room_id = ? ORDER BY inserted_at DESC LIMIT 1)",
          r.id
        )
      }

    Repo.all(query)
  end

  def join_room(attrs) do

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()

  end

  def new_message(attrs) do

    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()

  end

  def get_messages_by_room_id(room_id, user_id) do

    query = from m in Chat.Schemas.Message,
      join: ru in Chat.Schemas.User,
      on: ru.room_id == m.room_id and ru.user_id == ^user_id,
      where: m.room_id == ^room_id,
      select: m

    Repo.all(query)

  end

  def get_users_by_room_id(room_id) do

    query = from u in Chat.Schemas.User, where: u.room_id == ^room_id, select: u

    Repo.all(query)

  end

  def delete_room(room_id, user_id) do

    query = from r in Chat.Schemas.Room,
      where: r.id == ^room_id and r.onwer_id == ^user_id

    case Repo.one(query) do

      nil -> {:error, :not_found_or_not_owner}
      room -> Repo.delete(room)

    end

  end

  def get_user_name_by_id(user_id) do

    query = from u in Chat.Schemas.User, where: u.user_id == ^user_id, select: u.user_name

    Repo.all(query)

  end

  def upload_room_logo(room_id, file \\ nil) do

    key = "#{room_id}/logo/logo.png"

    case File.read(file.path) do

      {:ok, binary} ->

        Chat.Clients.S3.upload_file(binary, key, file.content_type)

        query = from r in Chat.Schemas.Room, where: r.id == ^room_id, update: [set: [logo_url: ^Chat.Clients.S3.build_key_url(key)]]

        Repo.update_all(query, [])

        {:ok, Chat.Clients.S3.build_key_url(key)}

      {:error, _reason} ->

        {:error}

    end

  end

end
