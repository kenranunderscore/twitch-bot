require "http/web_socket"

require "./parser"

def handle_ping(msg)
  puts "PING received:"
  puts msg
end

def handle_message(msg)
  puts "message received"
  msgs = msg.split("\r\n", remove_empty: true)
  msgs.map { |msg| puts Kenran::Parser.parse_message(msg) }
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
    @sock.send "CAP REQ :twitch.tv/commands twitch.tv/tags"
  end

  def run
    @sock.run
  end
end
