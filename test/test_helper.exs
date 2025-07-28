Mox.defmock(TokenStorageMock, for: Twitch.TokenStorage)
Application.ensure_all_started(:mox)
Application.put_env(:kenran_bot, :token_storage, TokenStorageMock)

ExUnit.start()
