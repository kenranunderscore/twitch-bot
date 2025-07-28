defmodule Twitch.AuthTest do
  use ExUnit.Case, async: true

  defmodule FakeTokenStorage do
    @behaviour Twitch.TokenStorage

    @impl Twitch.TokenStorage
    def save(_) do
      :ok
    end

    @impl Twitch.TokenStorage
    def load() do
      %Twitch.Tokens{
        access_token: "fooooo",
        refresh_token: "refoo",
        expires_at: nil
      }
    end
  end

  test "returns token from storage" do
    {:ok, pid} = Twitch.Auth.start_link({"the-secret", FakeTokenStorage})

    returned_token = Twitch.Auth.get_token(pid)
    assert returned_token == "fooooo"
  end
end
