module IRC
  record Server, host : String
  record User, nickname : String, host : String
  alias MessageSource = Server | User
  alias Tags = Hash(String, String)
  record PrivMsg, channel : String, message : String, source : MessageSource
  record Notice, channel : String, message : String
  record UnhandledCommand, content : String, remaining : String

  record Command, message : PrivMsg | Notice | UnhandledCommand, tags : Tags?
end
