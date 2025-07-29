defmodule KenranBot do
  @client_secret_file "client_secret"

  use Application

  @impl true
  def start(_type, _args) do
    {:ok, client_secret} = File.read(@client_secret_file)
    children = [{Twitch.Auth, client_secret: client_secret}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
