defmodule Kenran.Parser do
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

  defmodule Success do
    defstruct [:result, :remaining_input]
  end

  def succeed(result, remaining_input) do
    %Success{result: result, remaining_input: remaining_input}
  end

  def parse_message_source(msg) when is_binary(msg) do
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

  defp parse_source_parts(raw_message_source) do
    case String.split(raw_message_source, "!", parts: 2) do
      [nick, user] ->
        %{type: :user, nick: nick, user: user}

      [server] ->
        %{type: :server, name: server}
    end
  end

  def parse_raw_message(msg) when is_binary(msg) do
    case String.split(msg, ":", parts: 2) do
      [command_part, content] ->
        succeed(String.trim(command_part), content)

      [command_part] ->
        succeed(String.trim(command_part), "")
    end
  end

  def parse_message(msg) when is_binary(msg) do
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
        %Unspecified{kind: "", raw_text: remaining}
    end
  end

  def parse_tags(msg) when is_binary(msg) do
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

        [_tag, ""] ->
          []

        [_tag] ->
          []
      end
    end)
  end

  def parse_irc_command(msg) when is_binary(msg) do
    %Success{result: tags, remaining_input: after_tags} = parse_tags(msg)

    if tags do
      Logger.debug("parsed tags: #{inspect(tags)}")
    end

    %Success{result: source, remaining_input: after_source} = parse_message_source(after_tags)

    if source do
      Logger.debug("parsed source: #{inspect(source)}")
    end

    command_result = parse_message(after_source)

    cmd =
      case command_result do
        %PrivMsg{channel: channel, message: message} ->
          %{type: :privmsg, channel: channel, message: message, source: source}

        %Notice{channel: channel, message: message} ->
          %{type: :notice, channel: channel, message: message}

        %Unspecified{kind: kind, raw_text: raw_text} ->
          %{type: :unhandled, kind: kind, raw_text: raw_text}
      end

    Logger.debug("parsed command: #{inspect(command_result)}")

    %{command: cmd, tags: tags}
  end
end
