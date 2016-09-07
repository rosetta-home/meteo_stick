defmodule MeteoStick do
    use Application
    require Logger

    def start(_type, _args) do
        {:ok, pid} = MeteoStick.Supervisor.start_link
    end
end
