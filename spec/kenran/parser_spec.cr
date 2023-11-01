require "spec"

require "../../src/kenran/parser"

describe Kenran::Parser do
  describe "parsing the message source" do
    it "works for user messages" do
      msg = ":kenran__!kenran__@kenran__.tmi.twitch.tv PRIVMSG #kenran__ :blub"
      message_source = Kenran::Parser.parse_message_source msg
      expected = Kenran::Parser::MessageSource.new("kenran__", "kenran__@kenran__.tmi.twitch.tv")
      message_source[:source].should eq expected
    end
    it "works for server messages" do
      msg = ":kenranbot.tmi.twitch.tv 366 kenranbot #kenran__ :End of /NAMES list"
      message_source = Kenran::Parser.parse_message_source msg
      expected = Kenran::Parser::MessageSource.new(nil, "kenranbot.tmi.twitch.tv")
      message_source[:source].should eq expected
    end
  end

  describe "parsing the command" do
    it "works for user messages" do
      msg = "PRIVMSG #kenran__ :blub"
      result = Kenran::Parser.parse_raw_command msg
      expected = "PRIVMSG #kenran__"
      result[:raw_command].should eq expected
    end
    it "works for commands without parameters" do
      msg = "JOIN #kenran__"
      result = Kenran::Parser.parse_raw_command msg
      expected = "JOIN #kenran__"
      result[:raw_command].should eq expected
    end
  end
end
