defmodule MeteoStickTest do
  use ExUnit.Case
  doctest MeteoStick

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "events" do
      MeteoStick.EventManager.add_handler(MeteoStick.Handler)
      assert_receive %MeteoStick.WeatherStation.State{}, 30_000
  end
end
