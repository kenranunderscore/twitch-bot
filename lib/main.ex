defmodule Main do
  use Application

  @impl true
  def start(_type, _args) do
    {:ok, client} = Twitch.Client.load()
    {:ok, token} = Twitch.TokenStorage.load()
    children = [{Twitch.Auth, client: client, token: token}]
    res = Supervisor.start_link(children, strategy: :one_for_one)

    {:ok, pid} = Bot.start_link()
    Bot.authenticate(pid, token.access_token)

    Process.sleep(1500)
    res
  end
end
