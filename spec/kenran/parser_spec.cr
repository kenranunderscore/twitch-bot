require "spec"

require "../../src/kenran/parser"
require "../../src/kenran/irc_command"

describe Kenran::Parser do
  describe "trying to parse the tags" do
    it "succeeds if no tags can be found" do
      msg = "@badge-info=;badges=broadcaster/1 :abc!abc@abc.tmi.twitch.tv PRIVMSG #xyz :HeyGuys"
      res = Kenran::Parser.parse_tags msg
      expected_tags = ["badge-info=", "badges=broadcaster/1"]
      res.result.should eq expected_tags
    end
  end

  describe "parsing the message source" do
    it "works for user messages" do
      msg = ":kenran__!kenran__@kenran__.tmi.twitch.tv PRIVMSG #kenran__ :blub"
      res = Kenran::Parser.parse_message_source msg
      expected_source = Kenran::Parser::User.new("kenran__", "kenran__@kenran__.tmi.twitch.tv")
      res.result.should eq expected_source
    end
    it "works for server messages" do
      msg = ":kenranbot.tmi.twitch.tv 366 kenranbot #kenran__ :End of /NAMES list"
      res = Kenran::Parser.parse_message_source msg
      expected = Kenran::Parser::Server.new("kenranbot.tmi.twitch.tv")
      res.result.should eq expected
    end
  end

  describe "parsing the raw command" do
    it "works for user messages" do
      msg = "PRIVMSG #kenran__ :blub"
      res = Kenran::Parser.parse_raw_irc_command msg
      expected = "PRIVMSG #kenran__"
      res.result.should eq expected
      res.remaining_input.should eq "blub"
    end
    it "works for commands without parameters" do
      msg = "JOIN #kenran__"
      res = Kenran::Parser.parse_raw_irc_command msg
      expected = "JOIN #kenran__"
      res.result.should eq expected
    end
  end

  describe "parsing the IRC command" do
    describe "works for PRIVMSG" do
      it "with message text" do
        msg = "PRIVMSG #kenran__ :blub"
        res = Kenran::Parser.parse_irc_command msg
        res.should eq Kenran::IrcCommand::PrivMsg.new("#kenran__", "blub")
      end
      it "without message text" do
        msg = "PRIVMSG #kenran__"
        res = Kenran::Parser.parse_irc_command msg
        res.should eq Kenran::IrcCommand::PrivMsg.new("#kenran__", "")
      end
    end
  end
end
