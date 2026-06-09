defmodule ChatWeb.UserSocket do
  use Phoenix.Socket

  channel "room:*", ChatWeb.RoomChannel
  channel "user:*", UserWeb.UserChannel

  def connect(params, socket, _connect_info) do

    user_id = params["user_id"]
    user_name = params["user_name"]
    token = params["token"]

    case token do

      nil -> {:error, %{reason: "Missing token"}}

      token ->

        case Chat.User.verify_token(user_id, token) do

          true ->

            socket = socket
              |> assign(:user_id, user_id)
              |> assign(:user_name, user_name)
              |> assign(:token, token)

            {:ok, socket}

          false ->

            {:error, :unauthorized}

        end

    end
  end

  def id(socket) do

    "user:#{socket.assigns.user_id}"

  end

end
