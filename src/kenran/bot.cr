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

# Given a `WebSocket` and an access *token*, register a handler for Twitch IRC
# messages, and then `run` the chat client.
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
        result = Kenran::Parser.parse_irc_command(msg)
        handler.call result
      end
    else
      Log.debug { "received message, but no handler is set" }
      return
    end
  end

  # Register a handler that receives all `IRC::Command`s.
  def on_irc_command(&handler : IRC::Command ->)
    @command_handler = handler
  end

  # Send a message to the channel
  def send_msg(msg : String)
    @sock.send("PRIVMSG #kenran__ :" + msg)
  end

  # Reply to message by ID
  def reply_to(id : String, msg : String)
    tags = "@reply-parent-msg-id=#{id}"
    @sock.send("#{tags} PRIVMSG #kenran__ :" + msg)
  end

  # Actually start the chat client and run it indefinitely, calling the
  # registered IRC command handler for every message.
  def run
    authenticate
    @sock.run
  end
end
