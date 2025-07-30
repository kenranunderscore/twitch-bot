defmodule Twitch.Auth.Effect do
  use Efx

  @spec load_token() :: {:ok, %Twitch.Tokens{}} | {:error, term()}
  defeffect load_token() do
    Twitch.TokenStorage.load()
  end

  @spec refresh_token(%Twitch.Client{}, String.t()) ::
          {:ok, %Twitch.Tokens{}} | {:error, term()}
  defeffect refresh_token(client, refresh_token) do
    with {:ok, tokens} <- Twitch.Api.refresh_tokens(client, refresh_token),
         :ok <- Twitch.TokenStorage.save(tokens) do
      {:ok, tokens}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec refresh_token_after(integer()) :: any()
  defeffect refresh_token_after(seconds) do
    Process.send_after(self(), :refresh, seconds)
  end
end
