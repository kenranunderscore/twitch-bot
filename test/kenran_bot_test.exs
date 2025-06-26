defmodule KenranBotTest do
  use ExUnit.Case
  doctest KenranBot

  test "greets the world" do
    assert KenranBot.hello() == :world
  end
end
