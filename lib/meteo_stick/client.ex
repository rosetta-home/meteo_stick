defmodule MeteoStick.Client do
  use GenServer
  require Logger
  alias Nerves.UART, as: Serial

  defmodule State do
    defstruct stations: %{}
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
    {:ok, %State{}}
  end

  def handle_info({:nerves_uart, _serial, {:partial, _data}}, state) do
    {:noreply, state}
  end

  def handle_info({:nerves_uart, _serial, <<"B ", rest::binary>> = data}, state) do
    Logger.debug data
    case data |> String.ends_with?("%") do
      true ->
        parts = String.split(data, " ")
        MeteoStick.StationSupervisor |> Supervisor.which_children |> Enum.each( fn {_i, pid, _t, _m} ->
          pid |> MeteoStick.WeatherStation.data(parts)
        end)
      false -> :ok
    end
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


  def handle_data(data, state) do
    Logger.debug data
    parts = String.split(data, " ")
    type = parts |> Enum.at(0)
    id = :"MeteoStation-#{Enum.at(parts, 1)}"
    {_v, stations} =
      state.stations |> Map.get_and_update(id, fn val ->
        case val do
          nil -> {val, %{types: [type], data: [parts]}}
          other -> {other, %{other | types: [type | other.types], data: [parts | other.data]}}
        end
      end)
    stations =
      case ["W", "R", "T", "U", "S"] -- stations[id][:types] do
        [] ->
          stations[id][:data] |> Enum.each(fn data -> handle_station(id, data) end)
          stations |> Map.delete(id)
      _ -> stations
    end
    %State{state | stations: stations}
  end

  def handle_station(id, data) do
    case Process.whereis(id) do
      nil ->
        Logger.info "Starting Station: #{inspect data}"
        MeteoStick.StationSupervisor.start_station(data)
        _ -> :ok
    end
    MeteoStick.WeatherStation.data(id, data)
  end
end
