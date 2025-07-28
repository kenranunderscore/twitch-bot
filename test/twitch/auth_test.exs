defmodule Twitch.AuthTest do
  use ExUnit.Case, async: true

  defmodule FakePersistor do
    @behaviour Twitch.TokenPersistor

    @impl Twitch.TokenPersistor
    def persist_impl(_) do
      :ok
    end

    @impl Twitch.TokenPersistor
    def load_impl() do
      %Twitch.Tokens{
        access_token: "fooooo",
        refresh_token: "refoo",
        expires_at: nil
      }
    end
  end

  test "returns token from persistor" do
    {:ok, pid} = Twitch.Auth.start_link(FakePersistor)

    returned_token = Twitch.Auth.get_token(pid)
    assert returned_token == "fooooo"
  end
end
