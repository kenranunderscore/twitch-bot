defmodule Twitch.TokenStorage do
  alias Twitch.Tokens

  @callback save(%Tokens{}) :: :ok | {:error, term()}
  @callback load() :: %Tokens{} | {:error, term()}
end
