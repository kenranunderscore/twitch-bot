defmodule Twitch.Tokens do
  @derive {Jason.Encoder, []}
  @derive {Inspect, [only: [:expires_at]]}
  defstruct [:access_token, :refresh_token, :expires_at]

  def from_json(json) do
    case Jason.decode(json) do
      {:ok,
       %{
         "access_token" => access_token,
         "refresh_token" => refresh_token,
         "expires_in" => expires_in
       }} ->
        {:ok,
         %__MODULE__{
           access_token: access_token,
           refresh_token: refresh_token,
           expires_at: System.system_time(:second) + expires_in
         }}

      {:ok, _} ->
        {:error, :invalid_json_structure}

      {:error, reason} ->
        {:error, {:json_decode_error, reason}}
    end
  end
end
