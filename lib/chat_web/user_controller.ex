defmodule ChatWeb.UserController do
  use ChatWeb, :controller
  alias Chat.User

  def create_user(conn, params) do

    name = params["name"]
    avatar = params["avatar"]
    login = params["login"]
    password = params["password"]

    IO.inspect(params)

    case User.create_user(name, login, avatar, Bcrypt.hash_pwd_salt(password)) do

      {:ok, data} ->
          json(conn, data)

    end

  end

  def login_user(conn, params) do

    login = params["login"]
    password = params["password"]

    case User.auth_user(login, password) do

        {:ok, data} -> json(conn, data)
        {:error, :incorrect_data} -> send_resp(conn, 401, "")
        {:no_such_user} -> send_resp(conn, 401, "")

    end
  end

  def unlogin_user(conn, params) do

    user_id = params["user_id"]

    case User.delete_user(user_id) do

      {:ok} -> send_resp(conn, 200, "")
      {:error, :invalid_token} -> send_resp(conn, 401, "")
      {:error, :no_such_user} -> send_resp(conn, 403, "")

    end

  end

end
