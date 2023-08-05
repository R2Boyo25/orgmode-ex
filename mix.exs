defmodule Orgmode.MixProject do
  use Mix.Project

  def project do
    [
      app: :orgmode,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:leex] ++ [:yecc] ++ Mix.compilers(),
      leex_options: [erlc_paths: ["lib"]],
      yecc_options: [erlc_paths: ["lib"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_early_ret, "~> 0.1.0"},
      {:bang, "~> 0.1.0"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:fsmx, "~> 0.4.1"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end