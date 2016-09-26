defmodule MeteoStick.WeatherStation do
    use GenServer
    require Logger

    defmodule State do
        defstruct id: 0,
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
        id = Enum.at(data, 1)
        GenServer.start_link(__MODULE__, data, name: String.to_atom(id))
    end

    def data(station, data) do
        type = Enum.at(data, 0)
        values = Enum.drop(data, 1) |> Enum.map(&Float.parse/1)
        GenServer.call(station, {type, values})
    end

    def init(data) do
        {:ok, %State{id: Enum.at(data, 1)}}
    end

    def handle_call({"W", values}, _from, state) do
        [id, wind_speed, gust, wind_direction, rf_signal] = values
        Logger.debug("Wind Speed: #{inspect wind_speed}")
        Logger.debug("#{inspect values}")
        state = %State{state | wind: %{state.wind | speed: wind_speed |> elem(0), direction: wind_direction |> elem(0), gust: gust |> elem(0)}}
        GenEvent.notify(MeteoStick.Events, state)
        {:reply, :ok, state}
    end

    def handle_call({"R", values}, _from, state) do
        [id, tick, rf_signal] = values
        Logger.debug("Rain: #{inspect tick}")
        state = %State{state | rain: tick |> elem(0)}
        GenEvent.notify(MeteoStick.Events, state)
        {:reply, :ok, state}
    end

    def handle_call({"T", values}, _from, state) do
        [id, temp_c, humidity, rf_signal] = values
        Logger.debug("Temperature: #{inspect temp_c}")
        state = %State{state | outdoor_temperature: temp_c |> elem(0), humidity: humidity |> elem(0)}
        GenEvent.notify(MeteoStick.Events, state)
        {:reply, :ok, state}
    end

    def handle_call({"U", values}, _from, state) do
        [id, uv_index, rf_signal] = values
        Logger.debug("UV: #{inspect uv_index}")
        state = %State{state | :uv => uv_index |> elem(0)}
        GenEvent.notify(MeteoStick.Events, state)
        {:reply, :ok, state}
    end

    def handle_call({"S", values}, _from, state) do
        [id, solar_radiation, intensity, rf_signal] = values
        Logger.debug("Solar Radiation: #{inspect solar_radiation}")
        Logger.debug("#{inspect values}")
        state = %State{state | :solar => %{state.solar | radiation: solar_radiation |> elem(0), intensity: intensity |> elem(0)}}
        GenEvent.notify(MeteoStick.Events, state)
        {:reply, :ok, state}
    end

    def handle_call({"B", values}, _from, state) do
        [temp_c, pressure, good_packets] = values
        Logger.debug("Indoor Temperature: #{inspect temp_c}")
        state = %State{state | indoor_temperature: temp_c |> elem(0), pressure: pressure |> elem(0)}
        GenEvent.notify(MeteoStick.Events, state)
        {:reply, :ok, state}
    end

end
