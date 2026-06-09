defmodule UserWeb.UserChannel do
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

  def handle_info({:last_message_updated, room_name, room_id, type, logo, last_message, last_message_at, last_message_user_name, members}, socket) do

    push(socket, "last_message_updated", %{
      name: room_name,
      id: room_id,
      type: type,
      logo: logo,
      last_message: last_message,
      last_message_at: last_message_at,
      last_message_user_name: last_message_user_name,
      members: members
    })

  end

  def handle_info({:add_in_new_chat, room_name, room_id, type, logo, members}, socket) do #Юзер создал новый чат => запушили ему сообщение и всем кого он указал в members

    push(socket, "add_in_new_chat", %{
      name: room_name,
      id: room_id,
      type: type,
      logo: logo,
      members: members
    })

  end

  def handle_info({:user_delete_chat, user_name, room_id}, socket) do #Юзер создал новый чат => запушили ему сообщение и всем кого он указал в members

    push(socket, "user_delete_chat", %{
      user_name: user_name,
      room_id: room_id
    })

  end

  def handle_info(:send_chats_list, socket) do

    IO.puts("Запрос на получение комнат...")

    user_id = socket.assigns.user_id

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
