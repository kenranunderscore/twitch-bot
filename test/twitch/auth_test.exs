defmodule Twitch.AuthTest do
  use ExUnit.Case, async: true
  require Logger

  import Mox
  setup :verify_on_exit!

  test "returns token from storage" do
    TokenStorageMock
    |> expect(:load, fn ->
      %Twitch.Tokens{access_token: "fooooo", refresh_token: "rt", expires_at: nil}
    end)
    |> allow(self(), fn -> GenServer.whereis(Twitch.Auth) end)

    {:ok, pid} = Twitch.Auth.start_link("the-secret")

    returned_token = Twitch.Auth.get_token(pid)
    assert returned_token == "fooooo"
  end

  test "immediately refreshes expired tokens" do
    {:ok, t} = DateTime.new(~D[2025-07-01], ~T[00:00:00], "Etc/UTC")

    TokenStorageMock
    |> expect(:load, fn ->
      %Twitch.Tokens{
        access_token: "old",
        refresh_token: "ref",
        expires_at: DateTime.to_unix(t)
      }
    end)
    |> expect(:save, fn tokens -> :ok end)
    |> allow(self(), fn -> GenServer.whereis(Twitch.Auth) end)

    TwitchApiMock
    |> expect(:refresh_tokens, fn a, _, _ ->
      {:ok,
       %Twitch.Tokens{
         access_token: "new_token",
         refresh_token: "ref2",
         expires_at: DateTime.to_unix(t)
       }}
    end)
    |> allow(self(), fn -> GenServer.whereis(Twitch.Auth) end)

    {:ok, pid} = Twitch.Auth.start_link("the-secret")

    returned_token = Twitch.Auth.get_token(pid)
    assert returned_token == "new_token"
  end
end
