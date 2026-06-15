defmodule Chat.User do

  import Ecto.Query
  alias Chat.Repo
  alias Chat.Clients.Redis

  def create(name, login, avatar, password, fcm_token) do

    IO.puts("Recieved FCM Token: #{fcm_token}")

    case avatar do

			%Plug.Upload{} = upload ->

				case %User.Schemas.User{}
				|> User.Schemas.User.changeset(%{
								name: name,
								login: login,
								password: password
				})
				|> Repo.insert() do

					{:ok, user} ->

							auth_token =
									:crypto.strong_rand_bytes(32)
									|> Base.url_encode64(padding: false)

							add_authorization_pair(user.id, fcm_token, auth_token)

							upload_avatar(user.id, upload)

							{:ok, %{
									user_id: user.id,
									user_name: user.name,
									auth_token: auth_token
							}}

					{:error, changeset} ->
            IO.inspect(changeset.errors, label: "ERRORS")
            case changeset.errors[:login] do
              {_, [constraint: :unique, constraint_name: "users_login_index"]} ->
                {:error, :already_exists}
              _ -> {:error, :changeset}
            end

			end

    _ ->

		case %User.Schemas.User{}
			|> User.Schemas.User.changeset(%{
							name: name,
							login: login,
							avatar: avatar,
							password: password
			})
			|> Repo.insert() do

					{:ok, user} ->

							auth_token =
									:crypto.strong_rand_bytes(32)
									|> Base.url_encode64(padding: false)

							add_authorization_pair(user.id, fcm_token, auth_token)

							{:ok, %{
									user_id: user.id,
									user_name: user.name,
									auth_token: auth_token
							}}

					{:error, changeset} ->
            IO.inspect(changeset.errors, label: "ERRORS")
            case changeset.errors[:login] do
              {_, [constraint: :unique, constraint_name: "users_login_index"]} ->
                {:error, :already_exists}
              _ -> {:error, :changeset}
            end

				end

    end

  end

  def delete(user_id) do

    user = Repo.get(User.Schemas.User, user_id)

    Repo.delete(user)

    Redis.delete(user_id)

    {:ok}

  end

	def logout(user_id, fcm_token) do
    Redis.hdel(user_id, fcm_token)
	end

  def upload_avatar(user_id, file) do

    case File.read(file.path) do

			{:ok, binary} ->

        key = "#{user_id}/avatar/#{file.filename}"
        link = Chat.Clients.S3.build_key_url(key, "users")

        Chat.Clients.S3.upload_file(binary, key, file.content_type, "users")

        query = from u in User.Schemas.User, where: u.id == ^user_id, update: [set: [avatar: ^link]]

        Repo.update_all(query, [])

        {:ok, link}

    end

  end

  def get(user_id) do

    Repo.get(User, user_id)

  end

  def login(login, password, fcm_token) do

    IO.puts("Try connect. Login: #{login}, password: #{password}")

    query = from u in User.Schemas.User,
      where: u.login == ^login,
      select: {u.id, u.name, u.password}

    case Repo.one(query) do

      nil -> {:no_such_user}

      {user_id, user_name, origin_password} ->

        case Bcrypt.verify_pass(password, origin_password) do

          true ->

            auth_token =
              :crypto.strong_rand_bytes(32)
              |> Base.url_encode64(padding: false)

            Redis.hset(user_id, fcm_token, auth_token)

            {:ok, %{
              user_id: user_id,
              user_name: user_name,
              auth_token: auth_token
            }}

          false -> {:error, :incorrect_data}

        end

    end

  end

  def verify_token(user_id, fcm_token, auth_token) do
    case Redis.hget(user_id, fcm_token) do
      {:ok, ^auth_token} -> true
      _ -> false
    end
  end

  def add_authorization_pair(user_id, fcm_token, auth_token) do
    Redis.hset(user_id, fcm_token, auth_token)
  end

end
