defmodule MeteoStick.WeatherStation do
  use GenServer
  require Logger

  defmodule State do
      defstruct id: 0,
          low_battery: false,
          outdoor_temperature: 0,
          indoor_temperature: 0,
          humidity: 0,
          pressure: 0,
          wind: %{
              speed: 0,
              direction: 0,
              gust: 0
          },
          rain: 0,
          uv: 0,
          solar: %{
              radiation: 0,
              intensity: 0
          }
  end

  def start_link(data) do
      id = :"MeteoStation-#{Enum.at(data, 1)}"
      GenServer.start_link(__MODULE__, [id, data], name: id)
  end

  def data(station, data) do
      type = Enum.at(data, 0)
      values = Enum.drop(data, 1) |> Enum.map(fn(d) ->
          case Float.parse d do
              :error -> 0.0
              {num, remainder} -> num
          end
      end)
      GenServer.cast(station, {type, values})
  end

  def init([id, data]) do
      {:ok, %State{id: id}}
  end

  def handle_cast({"W", values}, state) do
      [id, wind_speed, gust, wind_direction, rf_signal] = values
      Logger.debug("Wind Speed: #{inspect wind_speed}")
      Logger.debug("#{inspect values}")
      state = %State{state | wind: %{state.wind | speed: wind_speed, direction: wind_direction, gust: gust}}
      GenEvent.notify(MeteoStick.Events, state)
      {:noreply, state}
  end

  def handle_cast({"R", values}, state) do
      [id, tick, rf_signal] = values
      Logger.debug("Rain: #{inspect tick}")
      state = %State{state | rain: tick}
      GenEvent.notify(MeteoStick.Events, state)
      {:noreply, state}
  end

  def handle_cast({"T", values}, state) do
    type = case values do
      [id, temp_c, humidity, signal] -> {:ok, id, temp_c, humidity, signal}
      [id, temp_c, humidity, signal, low_bat] -> {:lowbat, id, temp_c, humidity, signal, low_bat}
      _ ->:none
    end
    Logger.debug("T Type: #{inspect type}")
    state = case type do
      {:ok, id, temp_c, humidity, signal} -> %State{state | outdoor_temperature: temp_c, humidity: humidity, low_battery: false}
      {:lowbat, id, temp_c, humidity, signal, low_bat} -> %State {state | outdoor_temperature: temp_c, humidity: humidity, low_battery: true}
      :none -> state
    end
    GenEvent.notify(MeteoStick.Events, state)
    {:noreply, state}
  end

  def handle_cast({"U", values}, state) do
      [id, uv_index, rf_signal] = values
      Logger.debug("UV: #{inspect uv_index}")
      state = %State{state | :uv => uv_index}
      GenEvent.notify(MeteoStick.Events, state)
      {:noreply, state}
  end

  def handle_cast({"S", values}, state) do
      [id, solar_radiation, intensity, rf_signal] = values
      Logger.debug("Solar Radiation: #{inspect solar_radiation}")
      Logger.debug("#{inspect values}")
      state = %State{state | :solar => %{state.solar | radiation: solar_radiation, intensity: intensity}}
      GenEvent.notify(MeteoStick.Events, state)
      {:noreply, state}
  end

  def handle_cast({"B", values}, state) do
      type = case values do
        [temp_c, pressure, good_packets] -> {:meteo_stick, temp_c, pressure, good_packets}
        [id, pressure, signal, good_packets] -> {:barometer, pressure, signal, good_packets}
        _ -> :none
      end
      Logger.debug("Type: #{inspect type}")
      state = case type do
        {:meteo_stick, temp_c, pressure, good_packets} -> %State {state | indoor_temperature: temp_c, pressure: pressure}
        {:barometer, pressure, signal, good_packets} -> %State {state | pressure: pressure}
        :none -> state
      end
      GenEvent.notify(MeteoStick.Events, state)
      {:noreply, state}
  end

  def handle_cast({_id, _values}, state) do
    {:noreply, state}
  end

end
