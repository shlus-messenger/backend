defmodule Chat.Clients.Redis do
  def start_link(_opts \\ []) do
    redis_url = Application.get_env(:chat, :redis)[:url]

    IO.puts("Redis started on #{redis_url}")

    Redix.start_link(redis_url, name: __MODULE__)
  end

  def set(key, value) do
    Redix.command(__MODULE__, ["SET", key, value])
  end

  def delete(key) do
    Redix.command(__MODULE__, ["DEL", key])
  end

  def get(key) do
    Redix.command(__MODULE__, ["GET", key])
  end

  def sadd(key, value) do
    Redix.command(__MODULE__, ["SADD", key, value])
  end

  def sismember(key, value) do
    Redix.command(__MODULE__, ["SISMEMBER", key, value])
  end

  def srem(key, value) do
    Redix.command(__MODULE__, ["SREM", key, value])
  end

  def smembers(key) do
    Redix.command(__MODULE__, ["SMEMBERS", key])
  end

end
