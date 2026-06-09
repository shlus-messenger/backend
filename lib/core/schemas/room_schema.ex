defmodule Chat.Schemas.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "rooms" do

    field :name, :string
    field :owner_id, :binary_id
    field :logo, :string
    field :type, :string
    field :accessability, :string
    field :description, :string
    field :members, {:array, :string}

    timestamps()

  end

  def changeset(room, attrs) do

    room
    |> cast(attrs, [:id, :name, :owner_id, :logo, :type, :accessability, :members, :description])
    |> validate_required([:name, :owner_id])

  end

end
