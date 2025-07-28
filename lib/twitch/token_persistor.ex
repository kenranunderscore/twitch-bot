defmodule Twitch.TokenPersistor do
  alias Twitch.Tokens

  defp persistor() do
    Application.get_env(:kenran_bot, :persistor)
  end

  @callback persist_impl(%Tokens{}) :: :ok | {:error, term()}
  @callback load_impl() :: %Tokens{} | {:error, term()}

  def persist(tokens) do
    persistor().persist_impl(tokens)
  end

  def load() do
    persistor().load_impl()
  end
end
