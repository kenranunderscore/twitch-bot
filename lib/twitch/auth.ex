defmodule Twitch.Auth do
  @client_id "4ddd4mqxrq0wd60141980k3zpeyuvy"
  @access_token_file "token"
  @refresh_token_file "refresh_token"
  @client_secret_file "client_secret"
  @expires_at_file "expires_at"

  alias Twitch.Tokens

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_info(:refresh, state) do
    case update() do
      {:ok, _} ->
        {:noreply, state}

      {:error, reason} ->
        IO.puts("Could not refresh: #{reason}")
        {:noreply, state}
    end
  end

  def get_token, do: File.read(@access_token_file)

  defp update do
    with {:ok, refresh_token} <- File.read(@refresh_token_file),
         {:ok, client_secret} <- File.read(@client_secret_file),
         {:ok, tokens} <- Twitch.Api.refresh_tokens(@client_id, client_secret, refresh_token),
         :ok <- write_token_files(tokens) do
      dt = max(0, tokens.expires_at - System.system_time(:second) - 120)
      Process.send_after(self(), :refresh, dt)
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
      IO.puts("Successfully updated token files")
      :ok
    else
      {:error, reason} ->
        {:error, {:file_write_error, reason}}
    end
  end
end
