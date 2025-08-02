defmodule Main do
  use Application

  @impl true
  def start(_type, _args) do
    {:ok, client} = Twitch.Client.load()
    {:ok, token} = Twitch.TokenStorage.load()
    children = [{Twitch.Auth, client: client, token: token}]
    res = Supervisor.start_link(children, strategy: :one_for_one)

    auth_pid = GenServer.whereis(Twitch.Auth)
    access_token = Twitch.Auth.get_token(auth_pid)
    {:ok, bot_pid} = Bot.start_link()
    Bot.authenticate(bot_pid, access_token)
    res
  end
end
