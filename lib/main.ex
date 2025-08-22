defmodule Main do
  use Application

  @impl true
  def start(_type, _args) do
    {:ok, client} = Twitch.Client.load()
    {:ok, token} = Twitch.TokenStorage.load()
    children = [{Twitch.Auth, client: client, token: token}, {Bot, []}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
