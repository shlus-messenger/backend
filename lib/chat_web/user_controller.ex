defmodule ChatWeb.UserController do
  use ChatWeb, :controller
  alias Chat.User

  def create_user(conn, params) do

    name = params["name"]
    avatar = params["avatar"]
    login = params["login"]
    password = params["password"]

    fcm_token = case get_req_header(conn, "x-fcm-token") do
      [token] -> token
      _ -> nil
    end

    case User.create(name, login, avatar, Bcrypt.hash_pwd_salt(password), fcm_token) do

      {:ok, data} ->
        json(conn, data)
      {:error, :already_exists} ->
        send_resp(conn, 403, "User already exists")

    end

  end

  def check_user_exists(conn, params) do

    login = params["login"]

    json(conn, %{exists: Chat.is_user_exist(login)})

  end

  def login_user(conn, params) do

    login = params["login"]
    password = params["password"]
    fcm_token = params["fcm_token"]

    case User.login(login, password, fcm_token) do

        {:ok, data} -> json(conn, data)
        {:error, :incorrect_data} -> send_resp(conn, 401, "wrong password")
        {:no_such_user} -> send_resp(conn, 401, "")

    end
  end

  def logout_user(conn, params) do

    user_id = params["user_id"]
    fcm_token = conn.assigns.fcm_token

    User.logout(user_id, fcm_token)

    send_resp(conn, 200, "")

  end

end
