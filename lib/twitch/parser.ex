defmodule Twitch.Parser do
  require Logger

  defmodule PrivMsg do
    defstruct [:channel, :message]
  end

  defmodule Notice do
    defstruct [:channel, :message]
  end

  defmodule Unspecified do
    defstruct [:kind, :raw_text]
  end

  defmodule Command do
    defstruct [:command, :tags, :source]
  end

  defmodule Success do
    defstruct [:result, :remaining_input]
  end

  @spec succeed(term(), String.t()) :: %Success{}
  def succeed(result, remaining_input) do
    %Success{result: result, remaining_input: remaining_input}
  end

  @spec parse_message_source(String.t()) :: %Success{}
  def parse_message_source(msg) do
    case msg do
      ":" <> rest ->
        case String.split(rest, " ", parts: 2) do
          [raw_message_source, remaining] ->
            source = parse_source_parts(raw_message_source)
            succeed(source, remaining)

          [raw_message_source] ->
            source = parse_source_parts(raw_message_source)
            succeed(source, "")
        end

      _ ->
        succeed(nil, msg)
    end
  end

  @spec parse_source_parts(String.t()) ::
          %{type: :user, nick: String.t(), user: String.t()}
          | %{type: :server, name: String.t()}
  defp parse_source_parts(raw_message_source) do
    case String.split(raw_message_source, "!", parts: 2) do
      [nick, user] ->
        %{type: :user, nick: nick, user: user}

      [server] ->
        %{type: :server, name: server}
    end
  end

  @spec parse_raw_message(String.t()) :: %Success{}
  def parse_raw_message(msg) when is_binary(msg) do
    case String.split(msg, ":", parts: 2) do
      [command_part, content] ->
        succeed(String.trim(command_part), content)

      [command_part] ->
        succeed(String.trim(command_part), "")
    end
  end

  @spec parse_message(String.t()) :: %PrivMsg{} | %Notice{} | %Unspecified{}
  def parse_message(msg) do
    %Success{result: raw_result, remaining_input: remaining} = parse_raw_message(msg)
    parts = String.split(raw_result)

    case parts do
      ["PRIVMSG", channel | _] ->
        %PrivMsg{channel: channel, message: remaining}

      ["NOTICE", channel | _] ->
        %Notice{channel: channel, message: remaining}

      [command | _] ->
        %Unspecified{kind: command, raw_text: remaining}

      [] ->
        %Unspecified{kind: nil, raw_text: remaining}
    end
  end

  @spec parse_tags(String.t()) :: %Success{}
  def parse_tags(msg) do
    case msg do
      "@" <> rest ->
        case String.split(rest, " ", parts: 2) do
          [tags_string, remaining] ->
            tags = parse_tag_pairs(tags_string)
            result = if Enum.empty?(tags), do: nil, else: Map.new(tags)
            succeed(result, remaining)

          [tags_string] ->
            tags = parse_tag_pairs(tags_string)
            result = if Enum.empty?(tags), do: nil, else: Map.new(tags)
            succeed(result, "")
        end

      _ ->
        succeed(nil, msg)
    end
  end

  defp parse_tag_pairs(tags_string) do
    tags_string
    |> String.split(";")
    |> Enum.flat_map(fn tag_pair ->
      case String.split(tag_pair, "=", parts: 2) do
        [tag, value] when value != "" ->
          [{tag, value}]

        _ ->
          []
      end
    end)
  end

  @spec parse_irc_command(String.t()) :: %Command{}
  def parse_irc_command(msg) when is_binary(msg) do
    %Success{result: tags, remaining_input: after_tags} = parse_tags(msg)
    %Success{result: source, remaining_input: after_source} = parse_message_source(after_tags)
    cmd = parse_message(after_source)
    %Command{command: cmd, tags: tags, source: source}
  end
end
