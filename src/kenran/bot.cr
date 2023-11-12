require "json"

require "./parser"
require "../twitch"

# FIXME: logging

def handle_ping(msg)
  puts "PING received:"
  puts msg
end

def handle_message(msg)
  msgs = msg.split("\r\n", remove_empty: true)
  msgs.map do |msg|
    result = Kenran::Parser.parse_message(msg)
    puts result
  end
end

def on_close(close_code)
  puts "connection closed by Twitch: " + close_code.to_s
end

def connect
  sock = HTTP::WebSocket.new("wss://irc-ws.chat.twitch.tv:443")
  if sock
    sock.on_ping { |msg| handle_ping msg }
    sock.on_message { |msg| handle_message msg }
    sock.on_close { |msg| on_close msg }
    sock
  else
    raise "fatal: cannot connect to twitch"
  end
end

class Kenran::Bot
  def initialize(@sock : HTTP::WebSocket, @token : String)
  end

  private def authenticate
    @sock.send "PASS oauth:#{@token}"
    @sock.send "NICK kenranbot"
    @sock.send "JOIN #kenran__"
    @sock.send "CAP REQ :twitch.tv/commands twitch.tv/tags"
  end

  def run
    authenticate
    @sock.run
  end
end
