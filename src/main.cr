require "./kenran/bot"

CLIENT_ID = "m4oqqr7avpj8d52nbibmjfdu8yj17r"

2.times do
  sock = connect
  if sock
    token = Twitch.get_token
    bot = Kenran::Bot.new(sock, token)
    bot.run

    puts "bot stopped. refreshing access token"
    if !Twitch.update_tokens(CLIENT_ID)
      puts "couldn't update tokens"
    end
  end
end

puts "failed to run continuously. exiting"
exit 2
