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

  def regist_new_member(room_id, user_id) do

    room = get_room!(room_id)
    new_members = (room.members || []) ++ [user_id] |> Enum.uniq()

    room
    |> Room.changeset(%{members: new_members})
    |> Repo.update()

  end

  def get_all_public_rooms(amount) do

    query = from r in Chat.Schemas.Room,
      where: r.accessability == "public",
      limit: ^amount,
      select: %{
        id: r.id,
        name: r.name,
        type: r.type,
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
    query = from r in Chat.Schemas.Room,
      where: ^user_id in r.members,
      select: %{
        id: r.id,
        name: r.name,
        type: r.type,
        logo_url: r.logo_url,
				members: r.members,
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

  def create_user(attrs) do

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()

  end

  def change_user_status(user_id, status) when status in [:online, :offline] do

    user = Repo.get_by(User, user_id: user_id)

    if user do

      if status == :online do

        user
        |> User.changeset(%{status: "online"})
        |> Repo.update()

      else

        user
        |> User.changeset(%{status: "offline", last_seen_at: DateTime.utc_now()})
        |> Repo.update()

      end

    else

      {:error, :user_not_found}

    end

  end

  def new_message(attrs) do

    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()

  end

  def get_messages_by_room_id(room_id, user_id) do

    query = from m in Chat.Schemas.Message,
      join: r in Chat.Schemas.Room,
      on: m.room_id == r.id,
      where: m.room_id == ^room_id and ^user_id in r.members,
      select: m

    Repo.all(query)

  end

  def is_user_rooms_member(user_id, room_id) do

    query = from r in Chat.Schemas.Room,
			where: r.id == ^room_id and ^user_id in r.members,
			select: count(r.id)

		Repo.all(query) > 0

  end

  def get_room_name_by_room_id(room_id) do

    query = from r in Chat.Schemas.Room, where: r.id == ^room_id, select: r.name

    Repo.all(query)

  end

  def get_rooms_members(room_id) do

    query = from r in Chat.Schemas.Room, where: r.id == ^room_id, select: r.members

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
