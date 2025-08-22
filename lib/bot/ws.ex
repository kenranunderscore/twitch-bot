defmodule Bot.WS do
  @url "wss://irc-ws.chat.twitch.tv:443"

  use WebSockex
  require Logger

  def start_link(owner_pid) do
    WebSockex.start_link(@url, __MODULE__, %{owner: owner_pid})
  end

  def send_message(client, message) do
    WebSockex.send_frame(client, {:text, message})
  end

  @spec authenticate(pid(), String.t()) :: :ok
  def authenticate(pid, token) do
    send_message(pid, "PASS oauth:#{token}")
    send_message(pid, "NICK kenranbot")
    send_message(pid, "JOIN #kenran__")
    send_message(pid, "CAP REQ :twitch.tv/commands twitch.tv/tags")
    :ok
  end

  @impl WebSockex
  def handle_connect(_conn, state) do
    Logger.debug("Connected to Twitch")
    send(state.owner, :ws_connected)
    {:ok, state}
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    Logger.debug("Received: #{msg}")
    msg |> Twitch.Parser.parse_irc_command() |> IO.inspect()
    {:ok, state}
  end

  @impl WebSockex
  def handle_disconnect(%{reason: {:local, reason}}, state) do
    Logger.debug("Local disconnect: #{inspect(reason)}")
    {:ok, state}
  end

  @impl WebSockex
  def handle_disconnect(disconnect_map, state) do
    Logger.debug("Disconnect: #{inspect(disconnect_map)}")
    super(disconnect_map, state)
  end

  @impl WebSockex
  def handle_ping(frame, state) do
    Logger.debug("PING")
    super(frame, state)
  end
end
