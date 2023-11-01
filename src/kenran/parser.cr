module Kenran::Parser
  record MessageSource, nickname : String | Nil, host : String

  def self.parse_message_source(msg)
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
        {source: source, remaining: msg[next_space + 1..]}
      else
        {source: nil, remaining: msg}
      end
    else
      {source: nil, remaining: msg}
    end
  end

  def self.parse_raw_command(msg)
    command_end = msg.index(":")
    if command_end
      {raw_command: msg[0...command_end].strip, remaining: msg[command_end + 1..]}
    else
      {raw_command: msg[0..].strip, remaining: nil}
    end
  end

  def self.parse_message(msg)
    if msg[0] == '@'
      puts "cannot handle tags yet, dying"
      return
    end

    source_res = parse_message_source msg
    puts "parsed source: " + source_res.to_s
    rem = source_res[:remaining]

    command_res = parse_raw_command rem
    puts "raw command: " + command_res[:raw_command]
    raw_parameters = command_res[:remaining]
    if raw_parameters
      puts "parameters: " + raw_parameters[0..]
    end
  end
end
