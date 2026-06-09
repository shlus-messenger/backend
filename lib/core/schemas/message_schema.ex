defmodule Chat.Schemas.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :room_id, :user_id, :reply_to, :user_name, :body, :inserted_at]}

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "messages" do

    field :room_id, :binary_id
    field :user_id, :binary_id
    field :reply_to, :binary_id
    field :user_name, :string
    field :body, :string
    field :reactions, {:array, :integer}
    timestamps()

  end

  def changeset(message, attrs) do

    message
    |> cast(attrs, [:id, :room_id, :user_id, :reply_to, :user_name, :body, :reactions])
    |> validate_required([:room_id, :user_id, :user_name, :body])

  end

end
