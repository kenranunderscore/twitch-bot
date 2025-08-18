defmodule KenranBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :kenran_bot,
      version: "0.1.0",
      elixir: "~> 1.19-rc",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Main, []},
      extra_applications: [:logger, :efx]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.4.5", runtime: false},
      {:httpoison, "~> 0.4"},
      {:jason, "~> 1.4"},
      {:efx, "~> 1.0.0"},
      {:websockex, "~> 0.4.3"}
    ]
  end

  defp aliases do
    [test: ["test --no-start"]]
  end
end
