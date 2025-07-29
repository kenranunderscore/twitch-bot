defmodule Twitch.TokenStorage do
  @access_token_file "token"
  @expires_at_file "expires_at"
  @refresh_token_file "refresh_token"

  require Logger

  def save(%Twitch.Tokens{
        access_token: access_token,
        refresh_token: refresh_token,
        expires_at: expires_at
      }) do
    with :ok <- File.write(@access_token_file, access_token),
         :ok <- File.write(@expires_at_file, Integer.to_string(expires_at)),
         :ok <- File.write(@refresh_token_file, refresh_token) do
      Logger.info("Successfully stored token files")
      :ok
    else
      {:error, reason} ->
        {:error, {:file_write_error, reason}}
    end
  end

  def load() do
    with {:ok, access_token} <- File.read(@access_token_file),
         {:ok, refresh_token} <- File.read(@refresh_token_file),
         {:ok, t} <- File.read(@expires_at_file),
         {expires_at, _} <- Integer.parse(t) do
      %Twitch.Tokens{
        access_token: access_token,
        refresh_token: refresh_token,
        expires_at: expires_at
      }
    else
      :error ->
        raise "Cannot parse expiry date"

      {:error, reason} ->
        raise "Cannot open expired_at file: #{reason}"
    end
  end
end
