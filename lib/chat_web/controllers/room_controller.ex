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

  def leave_room(conn, params) do

    user_id = params["user_id"]
    room_id = params["room_id"]

    Chat.leave_room(room_id, user_id)

    ChatWeb.Endpoint.broadcast("user:#{user_id}", "user_left_chat", %{
      user_name: Chat.get_user_name_by_id(user_id),
      room: room_id
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

    case logo do

      %Plug.Upload{} = upload ->

        case Chat.Room.start_link(name, user_id, nil, accessability, type) do
          {:ok, _pid, room_data} ->

            logo_url = case Chat.upload_room_logo(room_data.id, upload) do

              {:ok, url} -> url
              _ -> nil

            end

            ChatWeb.Endpoint.broadcast("user:#{user_id}", "chat_updated", %{
              name: room_data.name,
              logo_url: logo_url,
              type: room_data.type,
              id: room_data.id,
              last_message: nil,
              last_message_at: nil,
              last_message_user_name: nil,
              members: room_data.members
            })

            json(conn, nil)

          {:error, _changeset} ->
            send_resp(conn, 403, "")
        end

      _ ->

        case Chat.Room.start_link(name, user_id, logo, accessability, type) do
          {:ok, _pid, room_data} ->

            ChatWeb.Endpoint.broadcast("user:#{user_id}", "chat_updated", %{
              name: room_data.name,
              logo_url: logo,
              type: room_data.type,
              id: room_data.id,
              last_message: nil,
              last_message_at: nil,
              last_message_user_name: nil,
              members: room_data.members
            })

            json(conn, nil)

          {:error, _changeset} ->
            send_resp(conn, 403, "")
        end

    end
  end
end
