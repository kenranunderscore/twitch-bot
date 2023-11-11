module Kenran::IrcCommand
  record PrivMsg, channel : String, message : String
  record Notice, channel : String, message : String
  record UnhandledCommand, content : String, remaining : String
end
