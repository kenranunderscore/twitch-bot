require "log"

require "./kenran/bot"

CLIENT_ID = "m4oqqr7avpj8d52nbibmjfdu8yj17r"

Log.setup(:notice)

2.times do
  sock = connect
  if sock
    token = Twitch.get_token
    client = TwitchChatClient.new(sock, token)
    client.on_irc_command do |cmd|
      Log.notice { cmd.to_s }
      message = cmd.message
      case message
      when IRC::PrivMsg
        tags = cmd.tags
        if tags
          first = tags["first-msg"]
          if first == "1"
            source = message.source
            case source
            when IRC::User
              client.reply_to(tags["id"].as(String), "HeyGuys")
            end
          end
        end
      end
    end
    client.run

    Log.notice { "bot stopped -> refreshing access token..." }
    Twitch.update_tokens(CLIENT_ID)
  end
end

Log.fatal { "couldn't keep the bot running" }
exit 2
