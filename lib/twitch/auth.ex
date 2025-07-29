defmodule Twitch.Auth do
  @client_id "4ddd4mqxrq0wd60141980k3zpeyuvy"

  require Logger

  use GenServer
  alias Twitch.Auth.Effect

  def get_token(pid \\ __MODULE__) do
    GenServer.call(pid, :get_token)
  end

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    client_secret = Keyword.fetch!(opts, :client_secret)
    GenServer.start_link(__MODULE__, client_secret, name: name)
  end

  @impl GenServer
  def init(client_secret) do
    # simon sagt ist kacke
    # -> doch in den state
    # -> struct
    # -> inspect-protokoll überschreiben
    Process.put(:client_secret, client_secret)
    tokens = Effect.load_token()

    if System.system_time(:second) > tokens.expires_at do
      Logger.info("Token has expired, refreshing...")

      case update(tokens.refresh_token) do
        {:ok, new_tokens} ->
          {:ok, new_tokens}

        {:error, reason} ->
          raise "Could not update expired token: #{reason}"
      end
    else
      Logger.info("Token is still valid")
      {:ok, tokens}
    end
  end

  @impl GenServer
  def handle_info(:refresh, tokens) do
    case update(tokens.refresh_token) do
      {:ok, new_tokens} ->
        {:noreply, new_tokens}

      {:error, reason} ->
        Logger.error("Could not refresh: #{reason}")
        {:noreply, tokens}
    end
  end

  @impl GenServer
  def handle_call(:get_token, _from, tokens) do
    {:reply, tokens.access_token, tokens}
  end

  defp update(refresh_token) do
    client_secret = Process.get(:client_secret)

    with {:ok, tokens} <- Effect.refresh_token(@client_id, client_secret, refresh_token),
         :ok <- Effect.save_token(tokens) do
      Logger.info("Successfully refreshed token")
      dt = max(0, tokens.expires_at - System.system_time(:second) - 120)
      # FIXME: effect!
      Process.send_after(__MODULE__, :refresh, dt)
      {:ok, tokens}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end
end
