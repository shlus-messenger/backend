defmodule ChatWeb.Router do
  use ChatWeb, :router

  pipeline :public_api do
    plug :accepts, ["json"]
  end

  pipeline :secure_api do
    plug :accepts, ["json"]
    plug ChatWeb.Plugs.Auth
  end

  scope "/", ChatWeb do
    pipe_through :secure_api

    get "/rooms/:user_id", RoomController, :get_rooms_by_user_id
  end

  scope "/", ChatWeb do
    pipe_through :secure_api

    get "/rooms", RoomController, :get_all_public_rooms

  end

  scope "/", ChatWeb do
    pipe_through :secure_api

    delete "/rooms/:user_id/:room_id", RoomController, :delete_room
  end

  scope "/", ChatWeb do
    pipe_through :secure_api

    post "/rooms", RoomController, :create_new_room

  end

  scope "/", ChatWeb do
    pipe_through :secure_api

    get "/messages/:user_id/:room_id", RoomController, :get_messages_by_room_id
  end

  scope "/", ChatWeb do
    pipe_through :secure_api

    get "/messages/:user_id/:room_id/last", RoomController, :get_last_room_message
  end

  scope "/", ChatWeb do
    pipe_through :public_api

    post "/user", UserController, :create_user
  end

  scope "/", ChatWeb do
    pipe_through :public_api

    post "/user/login", UserController, :login_user
  end

  scope "/", ChatWeb do
    pipe_through :secure_api

    delete "/user", UserController, :logout_user
  end

  scope "/", ChatWeb do
    pipe_through :public_api

    post "/user/check_existing", UserController, :check_user_exists
  end

end
