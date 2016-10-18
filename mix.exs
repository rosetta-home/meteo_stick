defmodule MeteoStick.Mixfile do
  use Mix.Project

  def project do
    [app: :meteo_stick,
     version: "0.1.6",
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
    A Client for the MeteoStick USB Stick
    """
  end

  def package do
    [
      name: :meteo_stick,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Christopher Steven Coté"],
      licenses: ["Apache License 2.0"],
      links: %{"GitHub" => "https://github.com/NationalAssociationOfRealtors/meteo_stick",
        "Docs" => "https://github.com/NationalAssociationOfRealtors/meteo_stick"}
    ]
  end

  defp deps do
    [
      {:nerves_uart, "~> 0.1.1"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
