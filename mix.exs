defmodule MeteoStick.Mixfile do
  use Mix.Project

  def project do
    [app: :meteo_stick,
     version: "0.1.1",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [
      applications: [:logger, :nerves_uart],
      mod: {MeteoStick, []},
      env: [speed: 115200,
          tty: "/dev/ttyUSB0",
      ]
    ]
  end

  def description do
    """
    A Client for the Rainforest Automation Raven USB SMCD (Smart Meter Connected Device)
    """
  end

  def package do
    [
      name: :raven_smcd,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Christopher Steven Coté"],
      licenses: ["MIT License"],
      links: %{"GitHub" => "https://github.com/NationalAssociationOfRealtors/raven",
        "Docs" => "https://github.com/NationalAssociationOfRealtors/raven"}
    ]
  end

  defp deps do
    [
      {:nerves_uart, "~> 0.1.1"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
