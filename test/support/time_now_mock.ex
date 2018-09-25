defmodule UrlShortener.TimeNowMock do

  def now do
    Timex.add(Timex.now(), Timex.Duration.from_seconds(2591995))
  end
end
