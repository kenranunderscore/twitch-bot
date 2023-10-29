require "http/web_socket"

def handle_ping(msg)
  puts "PING received:"
  puts msg
end

def handle_message(msg)
  puts "message received:"
  puts msg
end

class Bot
  def initialize
    @sock = HTTP::WebSocket.new("ws://irc-ws.chat.twitch.tv:80")
    # TODO: inject a token manager or sth like that to handle refreshes
    token = File.read "token"
    @sock.on_ping { |msg| handle_ping msg }
    @sock.on_message { |msg| handle_message msg }
    @sock.send "PASS oauth:#{token}"
    @sock.send "NICK kenranbot"
    @sock.send "JOIN #kenran__"
  end

  def run
    @sock.run
  end
end
