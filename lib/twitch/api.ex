defmodule Twitch.Api do
  alias Twitch.Token
  alias Twitch.Client

  def refresh_token(%Client{id: client_id, secret: client_secret}, refresh_token) do
    url = "https://id.twitch.tv/oauth2/token"

    body =
      URI.encode_query(
        grant_type: "refresh_token",
        refresh_token: refresh_token,
        client_id: client_id,
        client_secret: client_secret
      )

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response}} ->
        case Token.from_json(response) do
          {:ok, token} ->
            {:ok, token}

          {:error, reason} ->
            {:error, {:token_parse_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: response}} ->
        {:error, {:http_error, status_code, response}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end
end
