require "http/web_socket"

module Kenranbot
  VERSION = "0.1.0"

  ws = HTTP::WebSocket.new("ws://irc-ws.chat.twitch.tv:80")
  ws.on_ping do |msg|
    puts "  PING received"
    puts msg
  end
  ws.on_message do |msg|
    puts msg
  end
  token = File.read "token"
  ws.send "PASS oauth:#{token}"
  ws.send "NICK kenranbot"
  ws.send "JOIN #kenran__"
  ws.run
end
