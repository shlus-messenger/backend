defmodule Chat.Schemas.MessageReaction do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:message_id, :user_id, :user_name, :emoji, :reacted_at]}
  schema "message_reactions" do
    field :message_id, :binary_id
    field :user_id, :binary_id
    field :user_name, :string
    field :emoji, :string
    field :reacted_at, :utc_datetime_usec
  end

  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:message_id, :user_id, :user_name, :emoji, :reacted_at])
    |> validate_required([:message_id, :user_id, :user_name, :emoji])
  end
end
