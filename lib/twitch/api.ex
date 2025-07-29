defmodule Twitch.Api do
  @callback refresh_tokens(String, String, String) ::
              {:ok, %Twitch.Tokens{}} | {:error, term()}

  defp impl, do: Application.get_env(:kenran_bot, :twitch_api, Twitch.Api.IO)

  def refresh_tokens(client_id, client_secret, refresh_token) do
    impl().refresh_tokens(client_id, client_secret, refresh_token)
  end
end
