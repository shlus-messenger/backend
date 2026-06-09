defmodule Chat.Clients.Redis do

  def start_link(_opts \\ []) do
    Redix.start_link("redis://localhost:6379", name: __MODULE__)
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

end
