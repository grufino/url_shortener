defmodule UrlShortener.UrlLengthener do
  alias UrlShortener.Repo
  alias UrlShortener.Schema.Urls
  alias UrlShortener.Utils
  alias UrlShortener.Schema.UrlMetadata

  @task Application.get_env(:url_shortener, :task, Task)
  @time_now Application.get_env(:url_shortener, :time_now, Timex)
  @month_in_seconds 2_592_000

  def lengthen(short_url) do
    with schema = %Urls{id: db_id, full_url: full_url, valid_until: url_valid_date} <-
           Repo.get_by(Urls, short_url: short_url),
         true <- is_valid?(url_valid_date) do
      reset_validity(schema)
      {:ok, full_url, db_id}
    else
      false -> {:error, "The requested short url is not valid anymore"}
      nil -> {:not_found_error, "The requested short url does not exist"}
    end
  end

  defp is_valid?(url_valid_date) do
    @time_now.now()
    |> Timex.diff(url_valid_date) < @month_in_seconds
  end

  defp reset_validity(schema = %Urls{}) do
    schema
    |> Urls.changeset(%{valid_until: Utils.advance_one_month()})
    |> Repo.insert_or_update()
  end

  def build_final_url(parsed_uri, nil, new_params) when map_size(new_params) == 0,
    do: URI.to_string(parsed_uri)

  def build_final_url(parsed_uri, nil, new_params) do
    new_params_without_short_url =
      new_params
      |> URI.encode_query()

    parsed_uri
    |> Map.put(:query, new_params_without_short_url)
    |> URI.to_string()
  end

  def build_final_url(parsed_uri, old_params, new_params) do
    updated_query_params =
      old_params
      |> URI.query_decoder()
      |> Map.new()
      |> Map.merge(new_params)
      |> URI.encode_query()

    parsed_uri
    |> Map.put(:query, updated_query_params)
    |> URI.to_string()
  end

  def save_metadata_asynchronously(%Plug.Conn{req_headers: request_headers}, url_id) do
    @task.start(fn ->
      headers_map =
        request_headers
        |> Map.new
      %UrlMetadata{}
      |> UrlMetadata.changeset(%{urls_id: url_id, metadata: headers_map})
      |> Repo.insert()
    end)
  end
end
