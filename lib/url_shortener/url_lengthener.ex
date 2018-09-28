defmodule UrlShortener.UrlLengthener do

  alias UrlShortener.UrlManager
  alias UrlShortener.Schema.UrlMetadata
  alias UrlShortener.Repo

  @task Application.get_env(:url_shortener, :task, Task)

  def lengthen(short_url) do
    with [{_short_url, full_url}] <- :ets.lookup(:shortened_urls, short_url) do

      reset_validity(short_url)
      {:ok, full_url}
    else
      [] -> {:not_found_error, "The requested short url does not exist"}
    end
  end

  def reset_validity(short_url) do
    GenServer.cast(UrlManager, {:reset_validity, short_url})
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

  def save_metadata_asynchronously(%Plug.Conn{req_headers: request_headers}, short_url, full_url) do
    @task.start(fn ->
      headers_map =
        request_headers
        |> Map.new
      %UrlMetadata{}
      |> UrlMetadata.changeset(%{short_url: short_url, full_url: full_url, metadata: headers_map})
      |> Repo.insert()
    end)
  end
end
