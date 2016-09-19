defmodule MeteoStick do
  use Application
  require Logger
  alias Nerves.UART, as: Serial

  def start(_type, _args) do
    get_tty
    {:ok, pid} = MeteoStick.Supervisor.start_link
  end

  def get_tty do
    Serial.enumerate |> Enum.each(fn({tty, device}) ->
      case device.product_id do
        24577 ->
          Logger.info("Setting Meteo TTY: #{inspect tty}")
          Application.put_env(:meteo_stick, :tty, "/dev/#{tty}", persistent: true)
        _ -> nil
      end
    end)
  end

end
