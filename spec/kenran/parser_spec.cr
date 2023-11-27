require "spec"

require "../../src/kenran/parser"

describe Kenran::Parser do
  describe "trying to parse the tags" do
    it "succeeds if a tag can be found and parsed" do
      msg = "@badges=broadcaster/1 :abc!abc@abc.tmi.twitch.tv PRIVMSG #xyz :HeyGuys"
      res = Kenran::Parser.parse_tags msg
      expected_tags = {"badges" => "broadcaster/1"}
      res.result.should eq expected_tags
    end
    it "skips empty tags (i.e., without value)" do
      msg = "@badge-info=;badges=broadcaster/1 :abc!abc@abc.tmi.twitch.tv PRIVMSG #xyz :HeyGuys"
      res = Kenran::Parser.parse_tags msg
      expected_tags = {"badges" => "broadcaster/1"}
      res.result.should eq expected_tags
    end
    it "returns nil if all tags are empty" do
      msg = "@badge-info=;badges= :abc!abc@abc.tmi.twitch.tv PRIVMSG #xyz :HeyGuys"
      res = Kenran::Parser.parse_tags msg
      expected_tags = nil
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
      res = Kenran::Parser.parse_raw_message msg
      expected = "PRIVMSG #kenran__"
      res.result.should eq expected
      res.remaining_input.should eq "blub"
    end
    it "works for commands without parameters" do
      msg = "JOIN #kenran__"
      res = Kenran::Parser.parse_raw_message msg
      expected = "JOIN #kenran__"
      res.result.should eq expected
    end
  end

  describe "parsing the IRC command" do
    describe "works for PRIVMSG" do
      it "with message text" do
        msg = "PRIVMSG #kenran__ :blub"
        res = Kenran::Parser.parse_message msg
        res.should eq Kenran::Parser::PrivMsg.new("#kenran__", "blub")
      end
      it "without message text" do
        msg = "PRIVMSG #kenran__"
        res = Kenran::Parser.parse_message msg
        res.should eq Kenran::Parser::PrivMsg.new("#kenran__", "")
      end
    end
  end
end
