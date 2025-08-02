defmodule IrcTest do
  use ExUnit.Case, async: true

  alias Kenran.Parser.PrivMsg

  defp chat_message,
    do:
      "@badge-info=;badges=broadcaster/1,premium/1;client-nonce=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;color=#9ACD32;display-name=blubuser_display;emotes=;first-msg=0;flags=;id=00000000-0000-0000-0000-000000000000;mod=0;returning-chatter=0;room-id=22167345;subscriber=0;tmi-sent-ts=1754162532307;turbo=0;user-id=11111111;user-type= :blubuser!blubuser@blubuser.tmi.twitch.tv PRIVMSG #blubchan :hi3 you"

  describe "irc chat message" do
    test "message content can be parsed" do
      cmd = Kenran.Parser.parse_irc_command(chat_message())
      assert cmd.command == %PrivMsg{channel: "#blubchan", message: "hi3 you"}
    end

    test "tags can be parsed" do
      cmd = Kenran.Parser.parse_irc_command(chat_message())

      assert cmd.tags == %{
               "badges" => "broadcaster/1,premium/1",
               "client-nonce" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
               "color" => "#9ACD32",
               "display-name" => "blubuser_display",
               "first-msg" => "0",
               "id" => "00000000-0000-0000-0000-000000000000",
               "mod" => "0",
               "returning-chatter" => "0",
               "room-id" => "22167345",
               "subscriber" => "0",
               "tmi-sent-ts" => "1754162532307",
               "turbo" => "0",
               "user-id" => "11111111"
             }
    end

    test "source can be parsed" do
      cmd = Kenran.Parser.parse_irc_command(chat_message())

      assert cmd.source == %{
               type: :user,
               nick: "blubuser",
               user: "blubuser@blubuser.tmi.twitch.tv"
             }
    end
  end
end
