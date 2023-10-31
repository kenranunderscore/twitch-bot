require "http/web_socket"

record MessageSource, nickname : String | Nil, host : String

def handle_ping(msg)
  puts "PING received:"
  puts msg
end

def handle_message(msg)
  puts "message received"
  msgs = msg.split("\r\n", remove_empty: true)
  msgs.map { |msg| puts parse_message msg }
end

def parse_message_source(msg)
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

def parse_message(msg)
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

class Kenran::Bot
  def initialize
    @sock = HTTP::WebSocket.new("wss://irc-ws.chat.twitch.tv:443")
    # TODO: inject a token manager or sth like that to handle refreshes
    token = File.read "token"
    @sock.on_ping { |msg| handle_ping msg }
    @sock.on_message { |msg| handle_message msg }
    @sock.send "PASS oauth:#{token}"
    @sock.send "NICK kenranbot"
    @sock.send "JOIN #kenran__"
    @sock.send "PRIVMSG #kenran__ :I have joined the chat!"
  end

  def run
    @sock.run
  end
end
