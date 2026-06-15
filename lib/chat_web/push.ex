defmodule ChatWeb.Push do

  def send_push_notification(fcm_token, body) do

    case PushX.push(:fcm, fcm_token, %{title: "Новое сообщение", body: body}) do
      {:ok, %PushX.Response{status: :sent}} -> :ok
      {:error, %PushX.Response{status: :invalid_token}} -> :error
      {:error, %PushX.Response{}} -> :error
    end

  end

end
