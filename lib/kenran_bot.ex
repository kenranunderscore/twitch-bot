defmodule KenranBot do
  use Application

  @impl true
  def start(_type, _args) do
    persistor = Application.get_env(:kenran_bot, :persistor)
    children = [{Twitch.Auth, persistor}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
