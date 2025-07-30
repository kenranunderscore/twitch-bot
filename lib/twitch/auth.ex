defmodule Twitch.Auth do
  require Logger

  use GenServer
  alias Twitch.Auth.Effect

  defmodule State do
    defstruct [:tokens, :client]

    def set_tokens(state, tokens) do
      %{state | tokens: tokens}
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
    tokens = Effect.load_token()
    initial_state = %State{tokens: tokens, client: client}

    if System.system_time(:second) > tokens.expires_at do
      Logger.info("Token expired")

      case update(client, tokens.refresh_token) do
        {:ok, new_tokens} ->
          {:ok, initial_state |> State.set_tokens(new_tokens)}

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
    case update(state.client, state.tokens.refresh_token) do
      {:ok, new_tokens} ->
        Logger.info("Refreshed token automatically")
        {:noreply, new_tokens}

      {:error, reason} ->
        Logger.error("Failed token refresh: #{reason}")
        {:noreply, state.tokens}
    end
  end

  @impl GenServer
  def handle_call(:get_token, _from, state) do
    {:reply, state.tokens.access_token, state}
  end

  defp update(client, refresh_token) do
    Logger.info("Refreshing token...")

    case Effect.refresh_token(client, refresh_token) do
      {:ok, tokens} ->
        Logger.info("Refreshed token")
        dt = 1000 * max(0, tokens.expires_at - System.system_time(:second) - 120)
        Effect.refresh_token_after(dt)
        {:ok, tokens}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
