defmodule ChatWeb.UserController do
  use ChatWeb, :controller
  alias Chat.User

  def create_user(conn, params) do

    name = params["name"]
    avatar = params["avatar"]
    login = params["login"]
    password = params["password"]

    case User.create(name, login, avatar, Bcrypt.hash_pwd_salt(password)) do

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

    case User.login(login, password) do

        {:ok, data} -> json(conn, data)
        {:error, :incorrect_data} -> send_resp(conn, 401, "wrong password")
        {:no_such_user} -> send_resp(conn, 401, "")

    end
  end

  def logout_user(conn, params) do

    user_id = params["user_id"]
    token = conn.assigns.token

    User.logout(user_id, token)

    send_resp(conn, 200, "")

  end

end
