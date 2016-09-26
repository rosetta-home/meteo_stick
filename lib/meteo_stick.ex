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
      Logger.info("#{inspect device}")
      case Map.get(device, :product_id, 0) do
        24577 ->
          Logger.info("Setting Meteo TTY: #{inspect tty}")
          tty = case String.starts_with?(tty, "/dev") do
            true -> tty
            false -> "/dev/#{tty}"
          end
          Application.put_env(:meteo_stick, :tty, tty, persistent: true)
        _ -> nil
      end
    end)
  end

end
