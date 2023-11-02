module Kenran::Parser
  record MessageSource, nickname : String | Nil, host : String
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
          source = MessageSource.new(parts[0], parts[1])
        else
          source = MessageSource.new(nil, parts[0])
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

  def self.parse_message(msg)
    if msg[0] == '@'
      puts "cannot handle tags yet, dying"
      return
    end

    source_res = parse_message_source msg
    puts "parsed source: " + source_res.to_s
    rem = source_res.remaining_input

    command_res = parse_raw_command rem
    puts "parsed command: " + command_res.to_s
    raw_parameters = command_res.remaining_input
    if raw_parameters
      puts "parameters: " + raw_parameters[0..]
    end
  end
end
