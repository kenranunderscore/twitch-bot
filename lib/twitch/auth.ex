defmodule Twitch.Auth do
  require Logger

  use GenServer
  alias Twitch.Auth.Effect

  defmodule State do
    defstruct [:token, :client]

    def set_token(state, token) do
      %{state | token: token}
    end
  end

  def get_token(pid \\ __MODULE__) do
    GenServer.call(pid, :get_token)
  end

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    client = Keyword.fetch!(opts, :client)
    token = Keyword.fetch!(opts, :token)
    initial_state = %State{token: token, client: client}

    if System.system_time(:second) > token.expires_at do
      Logger.info("Token expired")

      case update(client, token.refresh_token) do
        {:ok, new_token} ->
          {:ok, initial_state |> State.set_token(new_token)}

        {:error, reason} ->
          raise "Failed token refresh: #{reason}"
      end
    else
      Logger.info("Token is still valid")
      {:ok, initial_state}
    end
  end

  @impl GenServer
  def handle_info(:refresh, state) do
    case update(state.client, state.token.refresh_token) do
      {:ok, new_token} ->
        Logger.info("Refreshed token automatically")
        {:noreply, new_token}

      {:error, reason} ->
        Logger.error("Failed token refresh: #{reason}")
        {:noreply, state.token}
    end
  end

  @impl GenServer
  def handle_call(:get_token, _from, state) do
    {:reply, state.token.access_token, state}
  end

  defp update(client, refresh_token) do
    Logger.info("Refreshing token...")

    case Effect.refresh_token(client, refresh_token) do
      {:ok, token} ->
        Logger.info("Refreshed token")
        dt = 1000 * max(0, token.expires_at - System.system_time(:second) - 120)
        Effect.refresh_token_after(dt)
        {:ok, token}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
