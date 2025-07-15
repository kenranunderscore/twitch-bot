defmodule KenranBot do
  @moduledoc """
  Documentation for `KenranBot`.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [{Twitch.Auth, nil}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
