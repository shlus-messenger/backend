defmodule Chat do

  alias Chat.Schemas.MessageReaction
  alias Chat.Repo
  alias Chat.Schemas.Room
  alias User.Schemas.User
  alias Chat.Schemas.Message
  import Ecto.Query

  def create_room(room_data) do


    case room_data.logo do

      %Plug.Upload{} = upload ->

        %Room{}
        |> Room.changeset(%{room_data | logo: nil})
        |> Repo.insert()

        case Chat.upload_room_logo(room_data.id, upload) do

          {:ok, url} ->
            {:ok, %{room_data | logo: url}}

          _error ->
            {:ok, room_data}

        end

      _ ->
        case %Room{}
        |> Room.changeset(room_data)
        |> Repo.insert() do

          {:ok, room} -> {:ok, room}

        end

    end
  end

  def get_room!(id) do

    Repo.get!(Room, id)

  end

  def list_rooms do

    Repo.all(Room)

  end

  def get_user_avatar_by_id(user_id) do

    query = from u in User,
      where: u.id == ^user_id,
      select: u.avatar

    Repo.one(query)

  end

  def get_message_by_id(message_id) do

    Repo.get(Message, message_id)

  end
  def regist_new_member(room_id, user_id) do

    room = get_room!(room_id)
    new_members = (room.members || []) ++ [user_id] |> Enum.uniq()

    room
    |> Room.changeset(%{members: new_members})
    |> Repo.update()

  end

  def get_all_public_rooms(amount) do

    query = from r in Room,
      where: r.accessability == "public",
      limit: ^amount,
      select: %{
        id: r.id,
        name: r.name,
        type: r.type,
        logo: r.logo,
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
    query = from r in Room,
      where: ^user_id in r.members,
      select: %{
        id: r.id,
        name: r.name,
        type: r.type,
        logo: r.logo,
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

    user = Repo.get_by(User, id: user_id)

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

  def delete_message(message_id) do

    case Repo.get(Message, message_id) do

      nil -> {:error, :not_found}
      message ->
        Repo.delete(message)

    end

  end

  def add_reaction(message_id, user_id, user_name, emoji, date) do

    case %MessageReaction{}
          |> MessageReaction.changeset(%{
            message_id: message_id,
            user_id: user_id,
            user_name: user_name,
            emoji: emoji,
            reacted_at: date
          })
          |> Repo.insert() do

      {:ok, reaction} ->

        case Repo.get(Message, message_id) do

          nil -> {:error, :not_found}

          message ->

            current_reactions = message.reactions || []
            updated_reactions = current_reactions ++ [reaction.id]

            message
            |> Message.changeset(%{reactions: updated_reactions})
            |> Repo.update!()

            reaction.id

        end

    end

  end

  def edit_message(message_id, new_body) do

    case Repo.get(Message, message_id) do

      nil -> {:error, :not_found}

      message ->
        message
        |> Message.changeset(%{body: new_body})
        |> Repo.update()

    end

  end

  def delete_reaction(message_id, reaction_id) do

    case Repo.get(Message, message_id) do

      nil -> {:error, :not_found}

      message ->

        current_reactions = message.reactions || []
        updated_reactions = current_reactions -- [reaction_id]

        message
        |> Message.changeset(%{reactions: updated_reactions})
        |> Repo.update()

        Repo.get(MessageReaction, reaction_id)
        |> Repo.delete()

    end


  end

  def new_message(attrs) do

    IO.puts("save message...")

    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()

  end

  def get_messages_by_room_id(room_id, user_id) do

    query = from m in Message,
      join: r in Room,
      on: m.room_id == r.id,
      where: m.room_id == ^room_id and ^user_id in r.members,
      select: m

    messages = Repo.all(query)

    messages
    |> Enum.map(&enrich_message/1)

  end

  def enrich_message(message, mode \\ :all)

  def enrich_message(%Message{reply_to: nil} = message, mode) do

    reactions = if mode == :all, do: get_reactions(message), else: []

    %{
      id: message.id,
      user_id: message.user_id,
      user_name: message.user_name,
      avatar: get_user_avatar_by_id(message.user_id),
      body: message.body,
      reactions: reactions,
      inserted_at: message.inserted_at,
      reply_to: nil
    }

  end

  def enrich_message(%Message{reply_to: reply_to_id} = message, mode) when not is_nil(reply_to_id) do

    reactions = if mode == :all, do: get_reactions(message), else: []

    case Repo.get(Message, reply_to_id) do

      nil ->
        %{
          id: message.id,
          user_name: message.user_name,
          user_id: message.user_id,
          body: message.body,
          avatar: get_user_avatar_by_id(message.user_id),
          reactions: reactions,
          inserted_at: message.inserted_at,
          reply_to: nil
        }

      reply_message ->
        %{
          id: message.id,
          user_name: message.user_name,
          user_id: message.user_id,
          body: message.body,
          reactions: reactions,
          avatar: get_user_avatar_by_id(message.user_id),
          inserted_at: message.inserted_at,
          reply_to: %{
            id: reply_message.id,
            user_name: reply_message.user_name,
            body: reply_message.body
          }
        }

    end
  end

  def get_reactions(%Message{} = message) do

    query = from r in MessageReaction,
      where: r.message_id == ^message.id,
      select: %{
        id: r.id,
        message_id: r.message_id,
        user_id: r.user_id,
        user_name: r.user_name,
        emoji: r.emoji,
        date: r.reacted_at
      }

    Repo.all(query)

  end

  def is_user_rooms_member(user_id, room_id) do

    query = from r in Room,
			where: r.id == ^room_id and ^user_id in r.members,
			select: count(r.id)

		Repo.all(query) > 0

  end

  def get_room_name_by_room_id(room_id) do

    query = from r in Room, where: r.id == ^room_id, select: r.name

    Repo.all(query)

  end

  def get_rooms_members(room_id) do

    query = from r in Room, where: r.id == ^room_id, select: r.members

    Repo.all(query)

  end

  def delete_room(room_id, user_id) do

    room = Repo.get(Room, room_id)

    if room.owner_id == user_id do

      Repo.delete!(room)

    else

      updated_members = Enum.reject(room.members, fn member -> member == user_id end)

      room
      |> Room.changeset(%{members: updated_members})
      |> Repo.update()

    end

  end

  def get_user_name_by_id(user_id) do

    query = from u in User, where: u.id == ^user_id, select: u.name

    Repo.all(query)

  end

  def upload_room_logo(room_id, file \\ nil) do

    key = "#{room_id}/logo/logo.png"

    case File.read(file.path) do

      {:ok, binary} ->

        Chat.Clients.S3.upload_file(binary, key, file.content_type, "chats")

        query = from r in Room, where: r.id == ^room_id, update: [set: [logo: ^Chat.Clients.S3.build_key_url(key, "chats")]]

        Repo.update_all(query, [])

        {:ok, Chat.Clients.S3.build_key_url(key, "chats")}

      {:error, _reason} ->

        {:error}

    end

  end

end
