defmodule ChatWeb.UserChannel do
  use Phoenix.Channel

  def join("user:" <> user_id, _payload, socket) do

    IO.puts("User (#{user_id}) trying connect...")

    if socket.assigns.user_id == user_id do

      send(self(), :send_chats_list)
      {:ok, assign(socket, :user_id, user_id)}

    else

      {:error, %{reason: "Unauthorized"}}

    end

  end

  def handle_info({:chat_updated, room_name, room_id, type, logo_url, last_message, last_message_at, last_message_user_name, members}, socket) do

    push(socket, "chat_updated", %{
      name: room_name,
      id: room_id,
      type: type,
      logo_url: logo_url,
      last_message: last_message,
      last_message_at: last_message_at,
      last_message_user_name: last_message_user_name,
      members: members
    })

  end

  def handle_info(:send_chats_list, socket) do

    user_id = socket.assigns.user_id

    Chat.change_user_status(user_id, :online)

    rooms = Chat.get_rooms_by_user_id(user_id)

    push(socket, "rooms_list", %{rooms: rooms})

    {:noreply, socket}

  end

  def terminate(_reason, socket) do

    user_id = socket.assigns.user_id

    Chat.change_user_status(user_id, :offline)

    IO.puts("User (#{user_id}) disconnected")

  end

end
