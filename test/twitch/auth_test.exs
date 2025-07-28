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
end
