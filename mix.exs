defmodule Tmp.MixProject do
  use Mix.Project

  @version "0.1.1"
  @github "https://github.com/preciz/tmp"

  def project do
    [
      app: :tmp,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      package: package(),
      description: "Temporary directories that are monitored and automatically removed",

      # Docs
      name: "Tmp",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [],
      mod: {Tmp.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Barna Kovacs"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github}
    ]
  end

  defp docs do
    [
      main: "Tmp",
      source_ref: "v#{@version}",
      source_url: @github
    ]
  end
end
