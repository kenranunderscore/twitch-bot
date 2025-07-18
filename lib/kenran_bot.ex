defmodule KenranBot do
  @access_token_file "token"
  @refresh_token_file "refresh_token"
  @expires_at_file "expires_at"

  use Application

  @impl true
  def start(_type, _args) do
    tokens =
      with {:ok, access_token} <- File.read(@access_token_file),
           {:ok, refresh_token} <- File.read(@refresh_token_file),
           {:ok, t} <- File.read(@expires_at_file),
           {expires_at, _} <- Integer.parse(t) do
        %Twitch.Tokens{
          access_token: access_token,
          refresh_token: refresh_token,
          expires_at: expires_at
        }
      else
        :error ->
          raise "Cannot parse expiry date"

        {:error, reason} ->
          raise "Cannot open expired_at file: #{reason}"
      end

    children = [{Twitch.Auth, tokens}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
