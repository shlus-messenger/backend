defmodule ChatWeb.RoomController do
  use ChatWeb, :controller

  def get_all_public_rooms(conn, params) do

    rooms = Chat.get_all_public_rooms(params["amount"])

    json(conn, %{rooms: rooms})

  end

  def get_rooms_by_user_id(conn, params) do

    rooms = Chat.get_rooms_by_user_id(params["user_id"])

    json(conn, %{rooms: rooms})

  end

  def get_messages_by_room_id(conn, params) do

    messages = Chat.get_messages_by_room_id(params["room_id"], params["user_id"])

    json(conn, %{messages: messages})

  end

  def create_new_room(conn, params) do

    name = params["name"]
    _description = params["description"]
    user_id = params["user_id"]
    logo = params["logo"]
    type = params["type"]
    accessability = params["accessability"]

    IO.inspect(params)

    case Chat.Room.start_link(name, user_id, "temp", accessability, type) do
      {:ok, _pid, room_data} ->

        logo_url = if logo do
          case Chat.upload_room_logo(room_data.id, logo) do

            {:ok, url} -> url
            _ -> :ok

          end
        end

        result = room_data
        |> Map.put(:logo_url, logo_url)

        json(conn, result)

      {:error, _changeset} ->
        send_resp(conn, 403, "")
    end
  end

end
