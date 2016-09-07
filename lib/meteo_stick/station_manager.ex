defmodule MeteoStick.StationSupervisor do
    use Supervisor
    require Logger

    def start_link do
        Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def init(:ok) do
        children = [
            worker(MeteoStick.WeatherStation, [], restart: :transient)
        ]
        supervise(children, strategy: :simple_one_for_one)
    end

    def start_station(data) do
        Logger.debug "Starting station: #{inspect data}"
        Supervisor.start_child(__MODULE__, [data])
    end
end
