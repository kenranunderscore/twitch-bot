module IRC
  alias Tags = Hash(String, String)
  record PrivMsg, channel : String, message : String
  record Notice, channel : String, message : String
  record UnhandledCommand, content : String, remaining : String

  record Command, message : PrivMsg | Notice | UnhandledCommand, tags : Tags?
end
