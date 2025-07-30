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

  @spec refresh_token(%Twitch.Client{}, String.t()) ::
          {:ok, %Twitch.Tokens{}} | {:error, term()}
  defeffect refresh_token(client, refresh_token) do
    Twitch.Api.refresh_tokens(client, refresh_token)
  end

  @spec refresh_token_after(integer()) :: any()
  defeffect refresh_token_after(seconds) do
    Process.send_after(self(), :refresh, seconds)
  end
end
