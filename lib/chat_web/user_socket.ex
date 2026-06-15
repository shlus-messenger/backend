defmodule ChatWeb.UserSocket do
  use Phoenix.Socket

  channel "room:*", ChatWeb.RoomChannel
  channel "user:*", UserWeb.UserChannel

  def connect(params, socket, _connect_info) do

    user_id = params["user_id"]
    user_name = params["user_name"]
    auth_token = params["auth_token"]
    fcm_token = params["fcm_token"]

    if is_nil(auth_token) && is_nil(fcm_token) do
      {:error, %{reason: "Missing token"}}
    end

    case Chat.User.verify_token(user_id, fcm_token, auth_token) do

      true ->

        socket = socket
          |> assign(:user_id, user_id)
          |> assign(:user_name, user_name)
          |> assign(:fcm_token, fcm_token)
          |> assign(:auth_token, auth_token)

        {:ok, socket}

      false ->

        {:error, :unauthorized}

    end
  end

  def id(socket) do

    "user:#{socket.assigns.user_id}"

  end

end
