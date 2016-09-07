defmodule MeteoStick.WeatherStation do
    use GenServer
    require Logger

    defmodule State do
        defstruct outdoor_temperature: 0,
            indoor_temperature: 0,
            humidity: 0,
            pressure: 0,
            wind: %{
                speed: 0,
                direction: 0
            },
            rain: 0,
            uv: 0,
            solar: %{radiation: 0 }
    end

    def start_link(data) do
        id = Enum.at(data, 1)
        Logger.debug("Starting: #{id}")
        GenServer.start_link(__MODULE__, data, name: String.to_atom(id))
    end

    def data(station, data) do
        Logger.debug("Handling Data: #{inspect station} #{inspect data}")
        type = Enum.at(data, 0)
        values = Enum.drop(data, 1) |> Enum.map(&Float.parse/1)
        GenServer.call(station, {type, values})
    end

    def init(data) do
        {:ok, %State{}}
    end

    def handle_call({"W", values}, _from, state) do
        [id, wind_speed, _other, wind_direction, rf_signal] = values
        Logger.debug("Wind Speed: #{inspect wind_speed}")
        Logger.debug("#{inspect values}")
        {:reply, :ok, %State{state | :wind => %{state.wind | speed: wind_speed, direction: wind_direction}}}
    end

    def handle_call({"R", values}, _from, state) do
        [id, tick, rf_signal] = values
        Logger.debug("Rain: #{inspect tick}")
        {:reply, :ok, %State{state | :rain => tick}}
    end

    def handle_call({"T", values}, _from, state) do
        [id, temp_c, humidity, rf_signal] = values
        Logger.debug("Temperature: #{inspect temp_c}")
        {:reply, :ok, %State{state | :outdoor_temperature => temp_c, :humidity => humidity}}
    end

    def handle_call({"U", values}, _from, state) do
        [id, uv_index, rf_signal] = values
        Logger.debug("UV: #{inspect uv_index}")
        {:reply, :ok, %State{state | :uv => uv_index}}
    end

    def handle_call({"S", values}, _from, state) do
        [id, solar_radiation, _other, rf_signal] = values
        Logger.debug("Solar Radiation: #{inspect solar_radiation}")
        Logger.debug("#{inspect values}")
        {:reply, :ok, %State{state | :solar => %{state.solar | :radiation => solar_radiation}}}
    end

    def handle_call({"B", values}, _from, state) do
        [temp_c, pressure, good_packets] = values
        Logger.debug("Indoor Temperature: #{inspect temp_c}")
        {:reply, :ok, %State{state | :indoor_temperature => temp_c, :pressure => pressure}}
    end

end
