defmodule UrlShortener.UrlShortener do
  alias UrlShortener.Repo
  alias UrlShortener.Schema.Urls
  alias UrlShortener.Utils

  def shorten(full_url) do
    short_url =
      full_url
      |> Murmur.hash_x86_32()
      |> :erlang.integer_to_binary(36)

    upsert(%{
      short_url: short_url,
      full_url: full_url,
      valid_until: Utils.advance_one_month()
    })
    |> case do
      {:ok, %Urls{short_url: short_url}} -> {:ok, short_url}
      {:error, message} -> {:error, message}
    end
  end

  def upsert(changes = %{short_url: short_url}) do
    case Repo.get_by(Urls, short_url: short_url) do
      nil  -> %Urls{}
      post -> post
    end
    |> Urls.changeset(changes)
    |> Repo.insert_or_update
  end
end
