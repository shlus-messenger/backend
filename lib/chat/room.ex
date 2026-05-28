defmodule Chat.Room do
  use GenServer

  def start_link(room_name, owner_id, logo_url \\ nil, accessability, room_type, room_id \\ nil) do

    case room_id do

      nil ->

        IO.puts("Создаём новую комнату...")

        case Chat.create_room(%{
          name: room_name,
          owner_id: owner_id,
          logo_url: logo_url,
          type: room_type,
          accessability: accessability,
          members: [owner_id]
        }) do

          {:ok, db_room} ->

            {:ok, pid} = GenServer.start_link(__MODULE__, [db_room.id, room_name], name: via_tuple(db_room.id))

            {:ok, pid, db_room}

          {:error, changeset} ->

            {:error, changeset}

        end

      id ->

        start_server(id, room_name)

    end
  end

  def start_server(room_id, room_name) do

    case GenServer.start_link(__MODULE__, [room_id, room_name], name: via_tuple((room_id))) do

      {:ok, pid} -> {:ok, pid, room_id}
      error -> error

    end

  end

  def send_message(room_id, user_id, user_name, message) do

    GenServer.cast(via_tuple(room_id), {:send_message, user_id, user_name, message})

  end


  def init([room_id, room_name]) do

    {:ok, %{
      room_id: room_id,
      room_name: room_name,
      messages: []
      }
    }

  end

  def handle_cast({:send_message, user_id, user_name, message}, state) do

    case Chat.new_message(%{
      room_id: state.room_id,
      user_id: user_id,
      user_name: user_name,
      body: message
    }) do

      {:ok, _db_message} ->

        new_message = %{user_id: user_id, user_name: user_name, message: message, timestamp: DateTime.utc_now()}
        new_state = %{state | messages: [new_message | state.messages]}

        {:noreply, new_state}

      {:error, _changeset} ->
        IO.puts("Failed to save message to database")
        {:noreply, state}


    end

  end

  def via_tuple(room_id) do

    {:via, Registry, {Chat.RoomRegistry, {:room, room_id}}}

  end

end
