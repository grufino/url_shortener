defmodule UrlShortener.Utils do

  def advance_one_month(time_now \\ Timex.now()) do
    time_now
    |> Timex.shift(days: 30)
  end
end
