defmodule ChatWeb.Plugs.Auth do
  import Plug.Conn
  import Phoenix.Controller
  alias Chat.User

  def init(opts), do: opts

  def call(conn, _opts) do
    IO.inspect(conn.req_headers, label: "Request headers")
    case get_token(conn) do
      {:ok, token, user_id} ->
        IO.puts("Token: " <> token)
        case User.verify_token(user_id, token) do
          true -> assign(conn, :user_id, user_id)
          false -> unauthorized(conn)
        end
      _ -> unauthorized(conn)
    end
  end

  defp get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        user_id = conn.params["user_id"] || conn.body_params["user_id"]
        {:ok, token, user_id}
      _ ->
        token = conn.params["token"]
        user_id = conn.params["user_id"]

        if token && user_id do
          {:ok, token, user_id}
        else
          :error
        end
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_status(401)
    |> json("")
    |> halt()
  end

end
