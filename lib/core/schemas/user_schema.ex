defmodule User.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "users" do

    field :name, :string
    field :login, :string
    field :avatar, :string
    field :password, :string
    field :about_me, :string
    timestamps()

  end

  def changeset(user, attrs) do

    user
    |> cast(attrs, [:name, :login, :avatar, :password, :about_me])
    |> validate_required([:name, :login, :password])

  end

end
