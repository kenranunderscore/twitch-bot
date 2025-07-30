defmodule Twitch.AuthTest do
  use ExUnit.Case, async: true
  use EfxCase

  require Logger

  alias Twitch.Auth.Effect

  test "returns token from storage", config do
    bind(Effect, :load_token, fn ->
      %Twitch.Tokens{access_token: "fooooo", refresh_token: "rt", expires_at: nil}
    end)

    {:ok, pid} = Twitch.Auth.start_link(client: %Twitch.Client{}, name: config.test)

    returned_token = Twitch.Auth.get_token(pid)
    assert returned_token == "fooooo"
  end

  test "immediately refreshes expired tokens", config do
    {:ok, t} = DateTime.new(~D[2025-07-01], ~T[00:00:00], "Etc/UTC")

    bind(Effect, :load_token, fn ->
      %Twitch.Tokens{
        access_token: "old",
        refresh_token: "ref",
        expires_at: DateTime.to_unix(t)
      }
    end)

    bind(Effect, :save_token, fn _ -> :ok end)

    bind(Effect, :refresh_token, fn _, _ ->
      {:ok,
       %Twitch.Tokens{
         access_token: "new_token",
         refresh_token: "ref2",
         expires_at: DateTime.to_unix(t)
       }}
    end)

    {:ok, pid} = Twitch.Auth.start_link(client: %Twitch.Client{}, name: config.test)

    returned_token = Twitch.Auth.get_token(pid)
    assert returned_token == "new_token"
  end
end
