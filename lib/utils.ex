defmodule UrlShortener.Utils do

  @timex Application.get_env(:url_shortener, :timex, Timex)

  def advance_one_month() do
    @timex.now()
    |> Timex.shift(days: 30)
  end
end
