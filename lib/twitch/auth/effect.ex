defmodule Twitch.Auth.Effect do
  use Efx

  @spec load_token() :: {:ok, %Twitch.Tokens{}} | {:error, term()}
  defeffect load_token() do
    Twitch.TokenStorage.load()
  end

  @spec save_token(%Twitch.Tokens{}) :: :ok
  defeffect save_token(tokens) do
    Twitch.TokenStorage.save(tokens)
  end

  @spec refresh_token(String.t(), String.t(), String.t()) ::
          {:ok, %Twitch.Tokens{}} | {:error, term()}
  defeffect refresh_token(client_id, client_secret, refresh_token) do
    Twitch.Api.refresh_tokens(client_id, client_secret, refresh_token)
  end
end
