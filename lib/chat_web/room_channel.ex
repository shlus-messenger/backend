defmodule ChatWeb.RoomChannel do
  use Phoenix.Channel
  alias Chat.Schemas.Message
  alias Chat.User

  def join("room:" <> room_id, _payload, socket) do
    user_id = socket.assigns.user_id
    token = socket.assigns.token

    case User.verify_token(user_id, token) do
      {:ok, 1} ->
        case Registry.lookup(Chat.RoomRegistry, {:room, room_id}) do
          [] ->
            room = Chat.get_room!(room_id)
            DynamicSupervisor.start_child(Chat.RoomSupervisor, {Chat.Room, [room.name, room_id]})
            Process.sleep(10)
          _ ->
            :ok
        end

        # Добавляем пользователя в комнату, если его нет
        unless Chat.is_user_rooms_member(user_id, room_id) do
          Chat.regist_new_member(room_id, user_id)
        end

        send(self(), :after_join)
        socket = assign(socket, :room_id, room_id)
        {:ok, socket}

      {:ok, 0} ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do

    user_id = socket.assigns.user_id
    user_name = socket.assigns.user_name

    ChatWeb.Presence.track(
      socket,
      user_id,
      %{
        user_name: user_name,
        online_at: System.system_time(:second)
      }
    )

    push(socket, "presence_state", ChatWeb.Presence.list(socket))

    {:noreply, socket}

  end

  def handle_in("typing", payload, socket) do

    [{user_name, typing}] = Map.to_list(payload)

    broadcast!(socket, "typing", %{
        user_name => typing
    })

    {:noreply, socket}

  end

  def handle_in("message_edit", %{"message_id" => message_id, "new_body" => new_body}, socket) do

    Chat.edit_message(message_id, new_body)

    broadcast!(socket, "message_edit", %{
      message_id: message_id,
      new_body: new_body
    })

    {:noreply, socket}

  end

  def handle_in("message_delete", %{"message_id" => message_id}, socket) do

    Chat.delete_message(message_id)

    broadcast!(socket, "message_delete", %{
      message_id: message_id,
    })

    {:noreply, socket}

  end

  def handle_in("add_reaction", %{"message_id" => message_id, "emoji" => emoji}, socket) do

    reaction_id = Chat.add_reaction(message_id, socket.assigns.user_id, socket.assigns.user_name, emoji, DateTime.utc_now())

    broadcast!(socket, "add_reaction", %{
      id: reaction_id,
      message_id: message_id,
      user_id: socket.assigns.user_id,
      user_name: socket.assigns.user_name,
      emoji: emoji,
      date: DateTime.utc_now()
    })

    {:noreply, socket}

  end

  def handle_in("delete_reaction", %{"message_id" => message_id, "reaction_id" => reaction_id}, socket) do

    Chat.delete_reaction(message_id, reaction_id)

    broadcast!(socket, "delete_reaction", %{
      id: reaction_id,
      message_id: message_id
    })

    {:noreply, socket}

  end

  def handle_in("new_message", %{"body" => body, "reply_to" => reply_to}, socket) do

    room = socket.assigns.room_id
    user_id = socket.assigns.user_id
    user_name = socket.assigns.user_name
		message_id = Ecto.UUID.generate()

    IO.puts("Handle message")

    Chat.Room.send_message(room, user_id, user_name, %{body: body, id: message_id, reply_to: reply_to})

    broadcast!(socket, "new_message", Chat.enrich_message(%Message{
      id: message_id,
      user_id: user_id,
      user_name: user_name,
      room_id: room,
      body: body,
      reactions: nil,
      reply_to: reply_to,
      inserted_at: DateTime.utc_now()
    }, :new))

    Chat.get_rooms_members(room)
    |> Enum.each(fn user ->
      ChatWeb.Endpoint.broadcast("user:#{user}", "last_message_updated", %{
        room_id: room,
        room_name: nil,
        logo: nil,
        type: nil,
        last_message: body,
        last_message_at: DateTime.utc_now(),
        last_message_user_name: user_name
      })
    end)

    {:noreply, socket}

  end

end
