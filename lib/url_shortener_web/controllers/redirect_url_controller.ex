defmodule UrlShortenerWeb.RedirectUrlController do
  use UrlShortenerWeb, :controller

  alias UrlShortener.UrlLengthener

  def redirect_url(conn, params) do
    with %{"shortUrl" => short_url} <- params,
         new_query_params <- Map.drop(params, ["shortUrl"]),
         {:ok, full_url} <- UrlLengthener.lengthen(short_url),
         parsed_uri = %URI{query: db_query_params} <- URI.parse(full_url) do

      UrlLengthener.save_metadata_asynchronously(conn, short_url, full_url)

      conn
      |> redirect(external: UrlLengthener.build_final_url(parsed_uri, db_query_params, new_query_params))
    else
      {:not_found_error, error_message} ->
        %{"error" => error_message}
        |> send_json_response(conn, 404)
    end
  end

  defp send_json_response(message, conn, status_code) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status_code, Poison.encode!(message))
  end
end
