defmodule ChatWeb.RoomChannel do
  use Phoenix.Channel

  def join("room:" <> room_id, _payload, socket) do

    IO.puts("Connecting...")

    user_id = socket.assigns.user_id

    if Chat.is_user_rooms_member(user_id, room_id) do

        send(self(), :after_join)

        socket = assign(socket, :room_id, room_id)
        {:ok, socket}

    else

        Chat.regist_new_member(room_id, user_id) # Тут будет логика обработки приватных групп, ключей приглашения и так далее

        {:ok, socket}

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

    IO.puts("Handle typing...")

    [{user_name, typing}] = Map.to_list(payload)

    broadcast!(socket, "typing", %{
        user_name => typing
    })

    {:noreply, socket}

  end

  def handle_in("new_message", %{"body" => body}, socket) do

    IO.puts("Handle some message...")

    room = socket.assigns.room_id
    user_id = socket.assigns.user_id
    user_name = socket.assigns.user_name

    Chat.Room.send_message(room, user_id, user_name, body)

    broadcast!(socket, "new_message", %{

      user_id: user_id,
      user_name: user_name,
      body: body,
      inserted_at: DateTime.utc_now()

    })

    Chat.get_rooms_members(room)
    |> Enum.each(fn user ->
      ChatWeb.Endpoint.broadcast("user:#{user}", "chat_updated", %{
        room_id: room,
        room_name: nil,
        logo_url: nil,
        type: nil,
        last_message: body,
        last_message_at: DateTime.utc_now(),
        last_message_user_name: user_name
      })
    end)

    {:noreply, socket}

  end

end
