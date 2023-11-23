require "log"

require "./kenran/bot"

CLIENT_ID = "m4oqqr7avpj8d52nbibmjfdu8yj17r"

Log.setup(:debug)

2.times do
  sock = connect
  if sock
    token = Twitch.get_token
    client = TwitchChatClient.new(sock, token)
    client.on_irc_command do |cmd|
      Log.debug { "command received" }
    end
    client.run

    Log.notice { "bot stopped -> refreshing access token..." }
    Twitch.update_tokens(CLIENT_ID)
  end
end

Log.fatal { "couldn't keep the bot running" }
exit 2
