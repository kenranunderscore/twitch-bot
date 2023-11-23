require "http/web_socket"
require "http/client"
require "log"

module Twitch
  ACCESS_TOKEN_FILE  = "token"
  REFRESH_TOKEN_FILE = "refresh_token"
  CLIENT_SECRET_FILE = "client_secret"

  class Tokens
    include JSON::Serializable
    property access_token : String
    property refresh_token : String
  end

  def self.get_token
    File.read ACCESS_TOKEN_FILE
  end

  def self.update_tokens(client_id : String) : Tokens?
    Log.info { "refreshing Twitch access token..." }
    refresh_token = File.read REFRESH_TOKEN_FILE
    client_secret = File.read CLIENT_SECRET_FILE
    HTTP::Client.post("https://id.twitch.tv/oauth2/token",
      headers: HTTP::Headers{"content-type" => "application/x-www-form-urlencoded"},
      body: "grant_type=refresh_token&refresh_token=#{refresh_token}&client_id=#{client_id}&client_secret=#{client_secret}",
      tls: true) do |response|
      if response.success?
        body = response.body_io.gets
        if body
          tokens = Tokens.from_json(body)
          File.write(REFRESH_TOKEN_FILE, tokens.refresh_token)
          File.write(ACCESS_TOKEN_FILE, tokens.access_token)
          Log.info { "successfully updated the token files" }
          tokens
        end
      else
        Log.error &.emit("couldn't update the token", response_body: response.body_io.gets)
      end
    end
  end
end
