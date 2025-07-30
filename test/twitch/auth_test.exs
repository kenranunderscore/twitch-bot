defmodule Twitch.AuthTest do
  use ExUnit.Case, async: true
  use EfxCase

  require Logger

  alias Twitch.Auth.Effect

  defp old_timestamp do
    {:ok, t} = DateTime.new(~D[2025-07-01], ~T[00:00:00], "Etc/UTC")
    t
  end

  defp expired_token do
    %Twitch.Tokens{
      access_token: "old",
      refresh_token: "ref",
      expires_at: DateTime.to_unix(old_timestamp())
    }
  end

  test "returns token from storage", config do
    {:ok, pid} =
      Twitch.Auth.start_link(
        client: %Twitch.Client{},
        tokens: %Twitch.Tokens{access_token: "fooooo", refresh_token: "rt", expires_at: nil},
        name: config.test
      )

    returned_token = Twitch.Auth.get_token(pid)
    assert returned_token == "fooooo"
  end

  describe "token refresh" do
    test "happens immediately when booting with expired tokens", config do
      bind(Effect, :refresh_token_after, fn _ -> nil end)

      bind(Effect, :refresh_token, fn _, _ ->
        {:ok,
         %Twitch.Tokens{
           access_token: "new_token",
           refresh_token: "ref2",
           expires_at: DateTime.to_unix(old_timestamp())
         }}
      end)

      {:ok, pid} =
        Twitch.Auth.start_link(
          client: %Twitch.Client{},
          tokens: expired_token(),
          name: config.test
        )

      returned_token = Twitch.Auth.get_token(pid)
      assert returned_token == "new_token"
    end

    test "is triggered automatically when necessary", config do
      # This is the automatic refresh "assignment" that should be triggered
      # exactly once
      bind(Effect, :refresh_token_after, fn _ -> nil end, calls: 1)

      bind(Effect, :refresh_token, fn _, _ ->
        {:ok,
         %Twitch.Tokens{
           access_token: "new_token",
           refresh_token: "ref2",
           expires_at: DateTime.to_unix(old_timestamp())
         }}
      end)

      {:ok, _} =
        Twitch.Auth.start_link(
          client: %Twitch.Client{},
          tokens: expired_token(),
          name: config.test
        )
    end
  end
end
