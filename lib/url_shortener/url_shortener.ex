defmodule UrlShortener.UrlShortener do

  alias UrlShortener.UrlManager

  def shorten(full_url) do
    short_url =
      full_url
      |> Murmur.hash_x86_32()
      |> :erlang.integer_to_binary(36)

      GenServer.cast(UrlManager, {:create_short, short_url, full_url})

      {:ok, short_url}
  end
end
