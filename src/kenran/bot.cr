require "http/web_socket"
require "http/client"
require "json"

require "./parser"

ACCESS_TOKEN_FILE = "token"
REFRESH_TOKEN_FILE = "refresh_token"

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

class Tokens
  include JSON::Serializable
  property access_token : String
  property refresh_token : String
end

def on_close(close_code)
  puts "connection closed by Twitch: " + close_code.to_s
  puts "trying to refresh the token..."
  refresh_token = File.read REFRESH_TOKEN_FILE
  client_secret = File.read "client_secret"
  HTTP::Client.post("https://id.twitch.tv/oauth2/token",
    headers: HTTP::Headers{"content-type" => "application/x-www-form-urlencoded"},
    body: "grant_type=refresh_token&refresh_token=#{refresh_token}&client_id=m4oqqr7avpj8d52nbibmjfdu8yj17r&client_secret=#{client_secret}",
    tls: true) do |response|
    if response.success?
      body = response.body_io.gets
      if body
        tokens = Tokens.from_json(body)
        File.write(REFRESH_TOKEN_FILE, tokens.refresh_token)
        File.write(ACCESS_TOKEN_FILE, tokens.access_token)
        puts "updated the token files"
      end
    else
      puts "couldn't update the token"
      exit 1
    end
  end
end

class Kenran::Bot
  def initialize
    @sock = HTTP::WebSocket.new("wss://irc-ws.chat.twitch.tv:443")
    # TODO: inject a token manager or sth like that to handle refreshes
    token = File.read ACCESS_TOKEN_FILE
    @sock.on_ping { |msg| handle_ping msg }
    @sock.on_message { |msg| handle_message msg }
    @sock.on_close { |msg| on_close msg }
    @sock.send "PASS oauth:#{token}"
    @sock.send "NICK kenranbot"
    @sock.send "JOIN #kenran__"
    @sock.send "CAP REQ :twitch.tv/commands twitch.tv/tags"
  end

  def run
    @sock.run
  end
end
