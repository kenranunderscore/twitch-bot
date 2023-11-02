require "spec"

require "../../src/kenran/parser"

describe Kenran::Parser do
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
      res = Kenran::Parser.parse_raw_command msg
      expected = "PRIVMSG #kenran__"
      res.result.should eq expected
    end
    it "works for commands without parameters" do
      msg = "JOIN #kenran__"
      res = Kenran::Parser.parse_raw_command msg
      expected = "JOIN #kenran__"
      res.result.should eq expected
    end
  end
end
