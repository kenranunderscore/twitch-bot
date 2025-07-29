defmodule Twitch.Client do
  @derive {Inspect, only: [:id]}
  defstruct [:id, :secret]

  def load() do
    case File.read(client_file()) do
      {:ok, content} ->
        case String.split(content, "\n", parts: 2) do
          [id, secret] ->
            {:ok, %__MODULE__{id: id, secret: secret}}

          _ ->
            {:error, :unexpected_client_file_format}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp client_file, do: "client"
end
