defmodule Twitch.Auth.Effect do
  use Efx

  @spec refresh_token(%Twitch.Client{}, String.t()) ::
          {:ok, %Twitch.Token{}} | {:error, term()}
  defeffect refresh_token(client, refresh_token) do
    with {:ok, token} <- Twitch.Api.refresh_token(client, refresh_token),
         :ok <- Twitch.TokenStorage.save(token) do
      {:ok, token}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec refresh_token_after(integer()) :: any()
  defeffect refresh_token_after(seconds) do
    Process.send_after(self(), :refresh, seconds)
  end
end
