defmodule ChatWeb.RoomChannel do
  use Phoenix.Channel

  def join("room:" <> room_id, _payload, socket) do

    IO.puts("Connecting...")

    user_id = socket.assigns.user_id
    user_name = socket.assigns.user_name

    case Chat.Room.join(room_id, %{id: user_id, name: user_name}) do

      {:ok, _users} ->

        IO.puts("✅ Monitor PID: #{inspect(self())}")
        Process.monitor(self())
        socket = assign(socket, :room_id, room_id)
        {:ok, socket}


      {:error, reason} ->

        IO.puts("❌ Join failed, reason: #{inspect(reason)}")
        {:error, %{reason: "join failed: #{inspect(reason)}"}}

    end

  end

  @spec handle_in(<<_::88>>, map(), Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
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
      timestamp: DateTime.utc_now()

    })

    {:noreply, socket}

  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do

    IO.puts("Пользователь отключается...")
    user = socket.assigns.user_id
    room = socket.assigns.room_id
    Chat.Room.leave(room, user)
    {:noreply, socket}

  end

end
