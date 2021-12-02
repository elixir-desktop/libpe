defmodule LibPE.MixProject do
  use Mix.Project

  @version "1.1.1"
  @url "https://github.com/elixir-desktop/libpe"

  def project do
    [
      app: :libpe,
      name: "LibPE",
      version: @version,
      source_url: @url,
      description: """
      Window PE file encoder & decoder
      """,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto]]
  end

  defp deps do
    [{:ex_doc, "~> 0.25", only: :dev, runtime: false}]
  end

  defp package do
    [
      maintainers: ["Dominic Letz"],
      licenses: ["MIT"],
      links: %{github: @url},
      files: ~w(lib LICENSE.md mix.exs README.md)
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @url,
      formatters: ["html"]
    ]
  end
end
