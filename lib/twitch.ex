defmodule Twitch.Auth do
  @client_id "4ddd4mqxrq0wd60141980k3zpeyuvy"
  @access_token_file "token"
  @refresh_token_file "refresh_token"
  @client_secret_file "client_secret"
  @expires_at_file "expires_at"

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, nil}
  end

  defmodule Tokens do
    @derive {Jason.Encoder, []}
    defstruct [:access_token, :refresh_token, :expires_at]

    def from_json(json) do
      case Jason.decode(json) do
        {:ok,
         %{
           "access_token" => access_token,
           "refresh_token" => refresh_token,
           "expires_in" => expires_in
         }} ->
          {:ok,
           %__MODULE__{
             access_token: access_token,
             refresh_token: refresh_token,
             expires_at: System.system_time(:second) + expires_in
           }}

        {:ok, _} ->
          {:error, :invalid_json_structure}

        {:error, reason} ->
          {:error, {:json_decode_error, reason}}
      end
    end
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
         {:ok, tokens} <- refresh_tokens(@client_id, client_secret, refresh_token),
         :ok <- write_token_files(tokens) do
      dt = max(0, tokens.expires_at - System.system_time(:second) - 120)
      Process.send_after(self(), :refresh, dt)
      {:ok, tokens}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp refresh_tokens(@client_id, client_secret, refresh_token) do
    url = "https://id.twitch.tv/oauth2/token"

    body =
      URI.encode_query(
        grant_type: "refresh_token",
        refresh_token: refresh_token,
        client_id: @client_id,
        client_secret: client_secret
      )

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response}} ->
        case Tokens.from_json(response) do
          {:ok, tokens} ->
            {:ok, tokens}

          {:error, reason} ->
            {:error, {:token_parse_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: response}} ->
        {:error, {:http_error, status_code, response}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
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
