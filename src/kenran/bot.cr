require "json"
require "log"

require "./parser"
require "../irc"
require "../twitch"

def handle_ping(msg)
  Log.debug { "PING received" }
end

def on_close(close_code)
  Log.notice &.emit("connection closed by Twitch", code: close_code.to_s)
end

def connect : HTTP::WebSocket
  sock = HTTP::WebSocket.new("wss://irc-ws.chat.twitch.tv:443")
  if !sock
    raise "fatal: cannot connect to twitch"
  end
  sock
end

class TwitchChatClient
  def initialize(@sock : HTTP::WebSocket, @token : String)
  end

  private def authenticate
    @sock.on_close { |code| on_close(code) }
    @sock.on_ping { |msg| handle_ping(msg) }
    @sock.on_message { |msg| handle_message(msg) }
    @sock.send "PASS oauth:#{@token}"
    @sock.send "NICK kenranbot"
    @sock.send "JOIN #kenran__"
    @sock.send "CAP REQ :twitch.tv/commands twitch.tv/tags"
  end

  private def handle_message(msg)
    handler = @command_handler
    if handler
      msgs = msg.split("\r\n", remove_empty: true)
      msgs.map do |msg|
        result = Kenran::Parser.parse_message(msg)
        handler.call result
      end
    else
      Log.debug { "received message, but no handler is set" }
      return
    end
  end

  def on_irc_command(&handler : IRC::Command ->)
    @command_handler = handler
  end

  def run
    authenticate
    @sock.run
  end
end
