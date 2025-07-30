defmodule KenranBot do
  use Application

  @impl true
  def start(_type, _args) do
    {:ok, client} = Twitch.Client.load()
    {:ok, tokens} = Twitch.TokenStorage.load()
    children = [{Twitch.Auth, client: client, tokens: tokens}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
