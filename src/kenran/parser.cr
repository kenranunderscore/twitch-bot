require "log"

require "../irc"

module Kenran::Parser
  Log = ::Log.for("parser")

  record PrivMsg, channel : String, message : String

  record Notice, channel : String, message : String

  record Unspecified, kind : String, raw_text : String

  alias Message = PrivMsg | Notice | Unspecified

  record Success(T), result : T, remaining_input : String

  def self.succeed(result, remaining_input)
    Success.new(result, remaining_input)
  end

  # Finds out where a message *msg* originates from and returns that parsed
  # `MessageSource`.
  def self.parse_message_source(msg)
    remaining = msg
    if msg[0] == ':'
      next_space = msg.index(" ", 1)
      if next_space
        raw_message_source = msg[1...next_space]
        parts = raw_message_source.split("!")
        if parts.size == 2
          source = IRC::User.new(parts[0], parts[1])
        else
          source = IRC::Server.new(parts[0])
        end
        remaining = msg[next_space + 1..]
      end
    end
    succeed(source, remaining)
  end

  def self.parse_raw_message(msg)
    command_end = msg.index(":")
    if command_end
      succeed(msg[0...command_end].strip, msg[command_end + 1..])
    else
      succeed(msg[0..].strip, "")
    end
  end

  def self.parse_message(msg)
    raw = parse_raw_message(msg)
    parts = raw.result.split(" ")
    case parts[0]
    when "PRIVMSG"
      PrivMsg.new(parts[1], raw.remaining_input)
    when "NOTICE"
      Notice.new(parts[1], raw.remaining_input)
    else
      Unspecified.new(parts[0], raw.remaining_input)
    end
  end

  def self.parse_tags(msg)
    if msg[0] != '@'
      return succeed(nil, msg)
    end

    # if the message contains tags, this has to exist
    next_space = msg.index(" ", 1).as(Int32)
    tags = Hash(String, String).new
    msg[1...next_space].split(";").each do |s|
      tag_name_end = s.index("=")
      if tag_name_end
        tag = s[0...tag_name_end]
        value = s[tag_name_end + 1..]
        if value != ""
          tags[tag] = value
        end
      end
    end
    return succeed(tags.empty? ? nil : tags, msg[next_space + 1..])
  end

  def self.parse_irc_command(msg)
    tags_res = parse_tags msg
    if tags_res.result
      Log.debug &.emit("parsed tags", tags: tags_res.result)
    end

    source_res = parse_message_source tags_res.remaining_input
    if source_res.result
      Log.debug &.emit("parsed source", message_source: source_res.result.to_s)
    end

    command_res = parse_message source_res.remaining_input
    case command_res
    when PrivMsg
      # source has to always be there for messages
      cmd = IRC::PrivMsg.new(command_res.channel, command_res.message, source_res.result.as(IRC::MessageSource))
    when Notice
      cmd = IRC::Notice.new(command_res.channel, command_res.message)
    else
      cmd = IRC::UnhandledCommand.new(command_res.kind, command_res.raw_text)
    end
    Log.debug &.emit("parsed command", command: command_res.to_s)

    IRC::Command.new(cmd, tags_res.result)
  end
end
