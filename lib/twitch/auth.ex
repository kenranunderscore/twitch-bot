defmodule Twitch.Auth do
  @client_id "4ddd4mqxrq0wd60141980k3zpeyuvy"

  require Logger

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init({client_secret, persistor}) do
    Process.put(:client_secret, client_secret)
    tokens = persistor.load_impl()

    if System.system_time(:second) > tokens.expires_at do
      Logger.info("Token is expired, refreshing...")

      case update(tokens.refresh_token, persistor) do
        {:ok, new_tokens} ->
          {:ok, {new_tokens, persistor}}

        {:error, reason} ->
          raise "Could not update expired token: #{reason}"
      end
    else
      Logger.info("Token is still valid")
    end

    {:ok, {tokens, persistor}}
  end

  @impl GenServer
  def handle_info(:refresh, {tokens, persistor}) do
    case update(tokens.refresh_token, persistor) do
      {:ok, new_tokens} ->
        {:noreply, {new_tokens, persistor}}

      {:error, reason} ->
        Logger.error("Could not refresh: #{reason}")
        {:noreply, {tokens, persistor}}
    end
  end

  def get_token(pid) do
    GenServer.call(pid, :get_token)
  end

  def get_token() do
    get_token(__MODULE__)
  end

  @impl GenServer
  def handle_call(:get_token, _from, {tokens, _persistor} = state) do
    {:reply, tokens.access_token, state}
  end

  defp update(refresh_token, persistor) do
    client_secret = Process.get(:client_secret)

    with {:ok, tokens} <- Twitch.Api.refresh_tokens(@client_id, client_secret, refresh_token),
         :ok <- persistor.persist_impl(tokens) do
      Logger.info("Successfully refreshed token")
      dt = max(0, tokens.expires_at - System.system_time(:second) - 120)
      Process.send_after(__MODULE__, :refresh, dt)
      {:ok, tokens}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end
end
