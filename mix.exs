defmodule Torrex.Mixfile do
  use Mix.Project

  def project do
    [app: :torrex,
     version: "0.1.2",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [:logger, :benx]]
  end

  defp deps do
    [{:benx, "~> 0.1.2"},
     {:ex_doc, "~> 0.14.5", only: :dev}]
  end

  defp description do
    """
    Create torrent files from single or multiple files.
    """
  end

  defp package do
    [name: :torrex,
     files: ["lib", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Sam Schneider"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/sschneider1207/torrex"}]
  end
end
