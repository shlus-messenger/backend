defmodule ChatWeb.Plugs.Auth do
  import Plug.Conn
  import Phoenix.Controller
  alias Chat.User

  def init(opts), do: opts

  def call(conn, _opts) do
    IO.inspect(conn.req_headers, label: "Request headers")
    case get_auth_pair(conn) do
      {:ok, auth_pair, user_id} ->
        case User.verify_token(user_id, auth_pair.fcm_token, auth_pair.auth_token) do
          true ->
            conn
            |> assign(:user_id, user_id)
            |> assign(:auth_token, auth_pair.auth_token)
            |> assign(:fcm_token, auth_pair.fcm_token)
          false -> unauthorized(conn)
        end
      _ -> unauthorized(conn)
    end
  end

  defp get_auth_pair(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> auth_token] ->
        user_id = conn.params["user_id"] || conn.body_params["user_id"]
        case get_req_header(conn, "x-fcm-token") do
          [fcm_token] ->
            {:ok, %{fcm_token: fcm_token, auth_token: auth_token}, user_id}
        end
      _ ->
        auth_token = conn.params["auth_token"]
        fcm_token = conn.params["fcm_token"]
        user_id = conn.params["user_id"]

        if auth_token && fcm_token && user_id do
          {:ok, %{auth_token: auth_token, fcm_token: fcm_token}, user_id}
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
