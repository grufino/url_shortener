defmodule UrlShortener.UrlManager do
  use GenServer
  require Logger

  alias UrlShortener.Utils

  @tab :shortened_urls
  @clean_after 86400

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(@tab, [:set, :named_table, :protected, read_concurrency: true, write_concurrency: true])
    Process.send_after(self(), :clean_expired, @clean_after)
    {:ok, %{}}
  end

  def handle_cast({:create_short, short_url, full_url}, state) do
    :ets.insert(@tab, {short_url, full_url})
    {:noreply, Map.put(state, short_url, Utils.advance_one_month())}
  end

  def handle_cast({:reset_validity, short_url}, state) do
    {:noreply, Map.put(state, short_url, Utils.advance_one_month())}
  end

  def handle_info(:clean_expired, state) do
    Logger.debug("Cleaning expired short urls")
    new_state = cleanup_and_reschedule(state)
    {:noreply, new_state}
  end

  defp cleanup_and_reschedule(state) do
    invalid_map =
      state
      |> Enum.filter(fn {_, valid_date} ->DateTime.diff(valid_date, Timex.now) < 0 end)

    invalid_map
    |> Enum.map(fn {short_url, _} -> :ets.delete(@tab, short_url) end)

    Process.send_after(self(), :clean_expired, @clean_after)

    invalid_keys =
      invalid_map
      |> Enum.map(fn {key, _value} -> key end)

    Map.drop(state, invalid_keys)
  end


end
