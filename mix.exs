defmodule LibPE.MixProject do
  use Mix.Project

  def project do
    [
      app: :libpe,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto]]
  end

  defp deps do
    [{:ex_doc, "~> 0.25", only: :dev, runtime: false}]
  end
end
