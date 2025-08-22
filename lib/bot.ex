defmodule Bot do
  require Logger
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(_opts) do
    {:ok, pid} = Bot.WS.start_link(self())
    {:ok, %{ws: pid}}
  end

  @impl GenServer
  def handle_info(:ws_connected, state) do
    auth_pid = GenServer.whereis(Twitch.Auth)
    access_token = Twitch.Auth.get_token(auth_pid)
    Bot.WS.authenticate(state.ws, access_token)
    {:noreply, state}
  end
end
