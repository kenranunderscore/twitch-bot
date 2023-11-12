require "./kenran/bot"

CLIENT_ID = "m4oqqr7avpj8d52nbibmjfdu8yj17r"

2.times do
  sock = connect
  if sock
    token = Twitch.get_token
    client = TwitchChatClient.new(sock, token)
    client.on_irc_command do |cmd|
      puts cmd
    end
    client.run

    puts "bot stopped. refreshing access token"
    if !Twitch.update_tokens(CLIENT_ID)
      puts "couldn't update tokens"
    end
  end
end

puts "failed to run continuously. exiting"
exit 2
