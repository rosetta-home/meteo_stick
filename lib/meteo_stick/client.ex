defmodule MeteoStick.Client do
    use GenServer
    require Logger
    alias Nerves.UART, as: Serial

    defmodule State do
        defstruct stations: [],
          new_stations: %{}
    end

    def start_link() do
        GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def open() do
      tty = Application.get_env(:meteo_stick, :tty)
      speed = Application.get_env(:meteo_stick, :speed)
      Logger.debug "Starting Serial: #{tty}"
      Serial.configure(MeteoStick.Serial, framing: {Serial.Framing.Line, separator: "\r\n"})
      Serial.open(MeteoStick.Serial, tty, speed: speed, active: true)
    end

    def close() do
      Serial.close(MeteoStick.Serial)
    end

    def init(:ok) do
        {:ok, serial} = Serial.start_link([{:name, MeteoStick.Serial}])
        open
        #Process.send_after(self, :bounce, 60000)
        {:ok, %State{}}
    end

    def handle_info(:bounce, state) do
      close
      open
      Process.send_after(self, :bounce, 60000)
      {:noreply, state}
    end

    def handle_info({:nerves_uart, _serial, {:partial, _data}}, state) do
        {:noreply, state}
    end

    def handle_info({:nerves_uart, _serial, <<"B ", rest::binary>> = data}, state) do
        parts = String.split(data, " ")
        Enum.each(state.stations, fn(s) ->
            MeteoStick.WeatherStation.data(s, parts)
        end)
        {:noreply, state}
    end

    def handle_info({:nerves_uart, _serial, <<"?">>}, state) do
        Serial.write(MeteoStick.Serial, "o1")
        Serial.write(MeteoStick.Serial, "m3")
        {:noreply, state}
    end

    def handle_info({:nerves_uart, _serial, {:error, :ebadf}}, state) do
        {:noreply, state}
    end

    def handle_info({:nerves_uart, _serial, data}, state) do
        state =
            case String.starts_with?(data, ["W", "R", "T", "U", "S"]) do
                true -> handle_data(data, state)
                false ->
                    Logger.error("Bad Data: #{inspect data}")
                    state
            end
        {:noreply, state}
    end

    def valid_data(parts, id) do
      case Process.whereis(id) do
        nil ->
          case parts |> Enum.at(0) do
            "T" ->
              case parts |> Enum.at(3) |> String.starts_with?("-") do
                true -> :nogo
                false -> :ok
              end
            _ -> :ok
          end
        _ -> :ok
      end
    end

    def valid_station(id, state) do
      ns = state.new_stations |> Map.get_and_update(id, fn(c_v) ->
        case c_v do
          nil -> {1, 1}
          other when other < 5 -> {other, other+1}
          _ -> {c_v, c_v}
        end
      end)
      {%State{state | new_stations: ns |> elem(1)}, ns |> elem(0)}
    end

    def handle_data(data, state) do
      Logger.debug data
      parts = String.split(data, " ")
      id = :"MeteoStation-#{Enum.at(parts, 1)}"
      case valid_data(parts, id) do
        :ok ->
          case valid_station(id, state) do
            {state, other} when other > 4 ->
              state = case Process.whereis(id) do
                nil ->
                    Logger.info "Starting Station: #{inspect parts}"
                    MeteoStick.StationSupervisor.start_station(parts)
                    %State{state | :stations => [id | state.stations]}
                _ -> state
              end
              MeteoStick.WeatherStation.data(id, parts)
              state
            {state, other} ->
              Logger.error "Not enough valid datapoints"
              state
          end
        :nogo ->
          Logger.error "Bad Data: #{inspect parts}"
          state
      end
    end

end
