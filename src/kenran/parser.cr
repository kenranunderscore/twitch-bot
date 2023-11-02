module Kenran::Parser
  record Server, host : String

  record User, nickname : String, host : String

  alias MessageSource = Server | User

  record Success(T), result : T, remaining_input : String

  def self.succeed(result, remaining_input)
    Success.new(result, remaining_input)
  end

  def self.parse_message_source(msg)
    remaining = msg
    if msg[0] == ':'
      next_space = msg.index(" ", 1)
      if next_space
        raw_message_source = msg[1...next_space]
        parts = raw_message_source.split("!")
        if parts.size == 2
          source = User.new(parts[0], parts[1])
        else
          source = Server.new(parts[0])
        end
        remaining = msg[next_space + 1..]
      end
    end
    succeed(source, remaining)
  end

  def self.parse_raw_command(msg)
    command_end = msg.index(":")
    if command_end
      succeed(msg[0...command_end].strip, msg[command_end + 1..])
    else
      succeed(msg[0..].strip, "")
    end
  end

  def self.parse_tags(msg)
    if msg[0] != '@'
      return succeed(nil, msg)
    end

    # if the message contains tags, this has to exist
    next_space = msg.index(" ", 1).as(Int32)
    all_pairs = msg[1...next_space].split(";")
    return succeed(all_pairs, msg[next_space + 1..])
  end

  def self.parse_message(msg)
    tags_res = parse_tags msg
    if tags_res.result
      puts "parsed tags: " + tags_res.to_s
    end

    source_res = parse_message_source tags_res.remaining_input
    if source_res.result
      puts "parsed source: " + source_res.to_s
    end

    command_res = parse_raw_command source_res.remaining_input
    puts "parsed command: " + command_res.to_s
    raw_parameters = command_res.remaining_input
    if raw_parameters
      puts "parameters: " + raw_parameters[0..]
    end
  end
end
