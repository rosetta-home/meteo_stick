defmodule MeteoStick.Handler do
    use GenEvent
    require Logger

    def init(parent) do
        {:ok, parent}
    end

    def handle_event(message, parent) do
        Logger.debug("Event Message #{inspect message}")
        send(parent, message)
        {:ok, parent}
    end
end
