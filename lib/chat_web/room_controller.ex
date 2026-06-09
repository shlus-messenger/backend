defmodule ChatWeb.RoomController do
  use ChatWeb, :controller

  def get_all_public_rooms(conn, params) do

    rooms = Chat.get_all_public_rooms(params["amount"])

    json(conn, rooms)

  end

  def get_rooms_by_user_id(conn, params) do

    rooms = Chat.get_rooms_by_user_id(params["user_id"])

    json(conn, rooms)

  end

  def get_messages_by_room_id(conn, params) do

    messages = Chat.get_messages_by_room_id(params["room_id"], params["user_id"])

    json(conn, messages)

  end

  def delete_room(conn, params) do

    user_id = params["user_id"]
    room_id = params["room_id"]

    Chat.delete_room(room_id, user_id)

    ChatWeb.Endpoint.broadcast("user:#{user_id}", "user_delete_chat", %{
      user_name: Chat.get_user_name_by_id(user_id),
      room_id: room_id
    })

    json(conn, params)

  end

  def create_new_room(conn, params) do

    name = params["name"]
    _description = params["description"]
    user_id = params["user_id"]
    logo = params["logo"]
    type = params["type"]
    accessability = params["accessability"]

      case Chat.Room.start_link(name, user_id, logo, accessability, type) do
        {:ok, _pid, room_data} ->

          ChatWeb.Endpoint.broadcast("user:#{user_id}", "add_in_new_chat", %{
            name: room_data.name,
            logo: room_data.logo,
            type: room_data.type,
            id: room_data.id,
            members: room_data.members
          })

          json(conn, nil)

        {:error, _changeset} ->
          send_resp(conn, 403, "")
      end
  end
end
