defmodule Twitch.Auth do
  @client_id "4ddd4mqxrq0wd60141980k3zpeyuvy"
  @access_token_file "token"
  @refresh_token_file "refresh_token"
  @client_secret_file "client_secret"
  @expires_at_file "expires_at"

  require Logger
  alias Twitch.Tokens

  use GenServer

  def start_link(tokens) do
    GenServer.start_link(__MODULE__, tokens, name: __MODULE__)
  end

  @impl true
  def init(tokens) do
    if System.system_time(:second) > tokens.expires_at do
      Logger.info("Token is expired, refreshing...")

      case update(tokens.refresh_token) do
        {:ok, new_tokens} ->
          {:ok, new_tokens}

        {:error, reason} ->
          raise "Could not update expired token: #{reason}"
      end
    else
      Logger.info("Token is still valid")
    end

    {:ok, tokens}
  end

  @impl true
  def handle_info(:refresh, tokens) do
    case update(tokens.refresh_token) do
      {:ok, new_tokens} ->
        {:noreply, new_tokens}

      {:error, reason} ->
        Logger.error("Could not refresh: #{reason}")
        {:noreply, tokens}
    end
  end

  def get_token() do
    GenServer.call(__MODULE__, :get_token)
  end

  def get_refresh_token() do
    GenServer.call(__MODULE__, :get_refresh_token)
  end

  @impl true
  def handle_call(:get_token, _from, tokens) do
    tokens.access_token
  end

  @impl true
  def handle_call(:get_refresh_token, _from, tokens) do
    tokens.refresh_token
  end

  defp update(refresh_token) do
    with {:ok, client_secret} <- File.read(@client_secret_file),
         {:ok, tokens} <- Twitch.Api.refresh_tokens(@client_id, client_secret, refresh_token),
         :ok <- write_token_files(tokens) do
      dt = max(0, tokens.expires_at - System.system_time(:second) - 120)
      Process.send_after(__MODULE__, :refresh, dt)
      {:ok, tokens}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp write_token_files(%Tokens{
         access_token: access_token,
         refresh_token: refresh_token,
         expires_at: expires_at
       }) do
    with :ok <- File.write(@access_token_file, access_token),
         :ok <- File.write(@expires_at_file, Integer.to_string(expires_at)),
         :ok <- File.write(@refresh_token_file, refresh_token) do
      Logger.info("Successfully updated token files")
      :ok
    else
      {:error, reason} ->
        {:error, {:file_write_error, reason}}
    end
  end
end
