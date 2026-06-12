defmodule Chat.Room do
  use GenServer

  def start_link([room_name, room_id]) do

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

    IO.puts("try to save message...")

    case Chat.new_message(%{
      room_id: state.room_id,
      user_id: user_id,
      user_name: user_name,
      reply_to: message.reply_to,
      body: message.body,
      id: message.id
    }) do

      {:ok, _db_message} ->

        new_message = %{user_id: user_id, reply_to: message.reply_to, user_name: user_name, message: message, timestamp: DateTime.utc_now()}
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
