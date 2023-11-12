module IRC
  record PrivMsg, channel : String, message : String
  record Notice, channel : String, message : String
  record UnhandledCommand, content : String, remaining : String

  alias Command = PrivMsg | Notice | UnhandledCommand
end
