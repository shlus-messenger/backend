defmodule ChatWeb.Router do
  alias ChatWeb.RoomController
  use ChatWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ChatWeb do
    pipe_through :api

    get "/rooms/:user_id", RoomController, :get_rooms_by_user_id
  end

  scope "/api", ChatWeb do
    pipe_through :api

    get "/rooms", RoomController, :get_all_public_rooms

  end

  scope "/api", ChatWeb do
    pipe_through :api

    get "/messages/:user_id/:room_id", RoomController, :get_messages_by_room_id
  end

  scope "/api", ChatWeb do
    pipe_through :api

    post "/rooms", RoomController, :create_new_room

  end

  scope "/api", ChatWeb do
    pipe_through :api

    get "/messages/:user_id/:room_id/last", RoomController, :get_last_room_message
  end

end
