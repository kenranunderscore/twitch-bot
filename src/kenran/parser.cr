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

  def self.parse_message(msg)
    if msg[0] == '@'
      puts "cannot handle tags yet, dying"
      return
    end

    source_res = parse_message_source msg
    puts "parsed source: " + source_res.to_s
    rem = source_res[:remaining]

    command_end = rem.index(":")
    if command_end
      command = rem[0...command_end]
      puts "command: " + command
      puts "parameters: " + rem[command_end + 1..]
    end
  end
end
