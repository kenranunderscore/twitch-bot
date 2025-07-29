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
      Logger.info("Token has expired, refreshing...")

      case update(client, tokens.refresh_token) do
        {:ok, new_tokens} ->
          {:ok, initial_state |> State.set_tokens(new_tokens)}

        {:error, reason} ->
          raise "Could not update expired token: #{reason}"
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
        {:noreply, new_tokens}

      {:error, reason} ->
        Logger.error("Could not refresh: #{reason}")
        {:noreply, state.tokens}
    end
  end

  @impl GenServer
  def handle_call(:get_token, _from, state) do
    {:reply, state.tokens.access_token, state}
  end

  defp update(client, refresh_token) do
    with {:ok, tokens} <- Effect.refresh_token(client, refresh_token),
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
