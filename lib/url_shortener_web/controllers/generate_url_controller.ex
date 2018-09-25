defmodule UrlShortenerWeb.GenerateUrlController do
  use UrlShortenerWeb, :controller

  alias UrlShortener.UrlShortener

  def generate_short_url(conn, %{"fullUrl" => full_url}) do
    with {:ok, short_url} <- UrlShortener.shorten(full_url) do
      send_json_response(%{"shortUrl" => short_url}, conn, 201)
    else
      {:error, error_message} -> send_json_response(error_message, conn, 400)
    end
  end

  defp send_json_response(message, conn, status_code) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status_code, Poison.encode!(message))
  end
end
