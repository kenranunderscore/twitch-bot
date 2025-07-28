defmodule Twitch.TokenStorage do
  alias Twitch.Tokens

  @callback save(%Tokens{}) :: :ok | {:error, term()}
  @callback load() :: %Tokens{} | {:error, term()}

  defp impl, do: Application.get_env(:kenran_bot, :token_storage, Twitch.TokenFileStorage)
  def save(tokens), do: impl().save(tokens)
  def load(), do: impl().load()
end
