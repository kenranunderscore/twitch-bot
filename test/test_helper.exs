Application.ensure_all_started(:mox)

Mox.defmock(TokenStorageMock, for: Twitch.TokenStorage)
Application.put_env(:kenran_bot, :token_storage, TokenStorageMock)

Mox.defmock(TwitchApiMock, for: Twitch.Api)
Application.put_env(:kenran_bot, :twitch_api, TwitchApiMock)

ExUnit.start()
