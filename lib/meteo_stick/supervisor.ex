defmodule MeteoStick.Supervisor do
    use Supervisor

    def start_link do
        Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def init(:ok) do
        children = [
            worker(MeteoStick.Client, []),
            worker(MeteoStick.EventManager, []),
            supervisor(MeteoStick.StationSupervisor, []),
        ]
        supervise(children, strategy: :one_for_one)
    end
end
