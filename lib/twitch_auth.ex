defmodule TwitchAuth do
  @client_id "4ddd4mqxrq0wd60141980k3zpeyuvy"
  @access_token_file "token"
  @refresh_token_file "refresh_token"
  @client_secret_file "client_secret"

  defmodule Tokens do
    @derive {Jason.Encoder, []}
    defstruct [:access_token, :refresh_token]

    @type t :: %__MODULE__{
            access_token: String.t(),
            refresh_token: String.t()
          }

    def from_json(json) do
      case Jason.decode(json) do
        {:ok, %{"access_token" => access_token, "refresh_token" => refresh_token}} ->
          {:ok, %__MODULE__{access_token: access_token, refresh_token: refresh_token}}

        {:ok, _} ->
          {:error, :invalid_json_structure}

        {:error, reason} ->
          {:error, {:json_decode_error, reason}}
      end
    end

    def to_json(%__MODULE__{} = tokens) do
      Jason.encode(tokens)
    end
  end

  def get_token, do: File.read(@access_token_file)

  def update() do
    IO.puts("refreshing access token for client #{@client_id}")

    with {:ok, refresh_token} <- File.read(@refresh_token_file),
         {:ok, client_secret} <- File.read(@client_secret_file),
         {:ok, tokens} <- refresh_tokens(@client_id, client_secret, refresh_token),
         :ok <- write_token_files(tokens) do
      IO.puts("successfully updated")
      {:ok, tokens}
    else
      {:error, reason} ->
        IO.puts("couldn't update token: #{inspect(reason)}")
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

  defp write_token_files(%Tokens{access_token: access_token, refresh_token: refresh_token}) do
    IO.puts("writing updated token files...")

    with :ok <- File.write(@access_token_file, access_token),
         :ok <- File.write(@refresh_token_file, refresh_token) do
      :ok
    else
      {:error, reason} ->
        {:error, {:file_write_error, reason}}
    end
  end
end
