defmodule UrlShortenerWeb.ControllersTest do
  use UrlShortenerWeb.ConnCase, async: true

  alias UrlShortener.Schema.Urls
  alias UrlShortener.Schema.UrlMetadata
  alias UrlShortener.Repo

  setup do
    # Explicitly get a connection before each test
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok
  end

  test "responds with shorter URL in json format", %{conn: conn} do
    original = "http://example.com/about/index.html"

    response = post(conn, "api/generate_short_url", fullUrl: original)

    %{"shortUrl" => short_url} = response.resp_body |> Poison.decode!()

    assert response.status == 201

    assert String.length(short_url) < String.length(original)
  end

  test "responds with different short URLs for different long URLs in json format", %{conn: conn} do
    original_1 = "http://example.com/about/index.html"

    original_2 = "http://example.com/about/url_to_be_shortened"

    response_1 = post(conn, "api/generate_short_url", fullUrl: original_1)

    %{"shortUrl" => short_url_1} = response_1.resp_body |> Poison.decode!()

    response_2 = post(conn, "api/generate_short_url", fullUrl: original_2)

    %{"shortUrl" => short_url_2} = response_2.resp_body |> Poison.decode!()

    assert short_url_1 != short_url_2
  end

  test "redirects to long url when shortened one created by this api provided", %{conn: conn} do
    original = "http://example.com/about/index.html"

    response = post(conn, "api/generate_short_url", fullUrl: original)

    %{"shortUrl" => short_url} = response.resp_body |> Poison.decode!()

    conn = get(conn, "/#{short_url}")

    assert redirected_to(conn) == original
    assert conn.status == 302
  end

  test "long URL is always responded with the same short url", %{conn: conn} do
    original = "http://example.com/about/index.html"

    response_1 = post(conn, "api/generate_short_url", fullUrl: original)

    response_2 = post(conn, "api/generate_short_url", fullUrl: original)

    response_3 = post(conn, "api/generate_short_url", fullUrl: original)

    %{"shortUrl" => short_url_1} = response_1.resp_body |> Poison.decode!()

    %{"shortUrl" => short_url_2} = response_2.resp_body |> Poison.decode!()

    %{"shortUrl" => short_url_3} = response_3.resp_body |> Poison.decode!()

    assert short_url_1 == short_url_2
    assert short_url_2 == short_url_3
  end

  test "expires url after 1 month (with mocked time_now to 5 seconds before 1 month on TimeNowMock.time_now())",
       %{conn: conn} do
    original = "http://example.com/about/expire_this_url"

    response = post(conn, "api/generate_short_url", fullUrl: original)

    %{"shortUrl" => short_url} = response.resp_body |> Poison.decode!()

    :timer.sleep(10000)

    response = get(conn, "/#{short_url}")

    assert %{"error" => "The requested short url is not valid anymore"} =
             response.resp_body |> Poison.decode!()
  end

  test "doesn't expire url because of redirect (with mocked time_now to 5 seconds before 1 month on TimeNowMock.time_now())",
       %{conn: conn} do
    original = "http://example.com/about/this_should_not_expire"

    short_url_response = post(conn, "api/generate_short_url", fullUrl: original)

    %{"shortUrl" => short_url} = short_url_response.resp_body |> Poison.decode!()

    :timer.sleep(3000)

    get_response_1 = get(conn, "/#{short_url}")

    :timer.sleep(3000)

    get_response_2 = get(conn, "/#{short_url}")

    assert redirected_to(get_response_1) == original
    assert redirected_to(get_response_2) == original
  end

  test "uniqueness in urls table", %{conn: conn} do
    original = "http://example.com/about/this_should_generate_only_one_entry_in_db"

    post(conn, "api/generate_short_url", fullUrl: original)

    post(conn, "api/generate_short_url", fullUrl: original)

    response_3 = post(conn, "api/generate_short_url", fullUrl: original)

    %{"shortUrl" => short_url} = response_3.resp_body |> Poison.decode!()

    assert %UrlShortener.Schema.Urls{
             full_url: db_original,
             short_url: db_short
           } = Repo.get_by(Urls, full_url: original)

    assert db_original == original
    assert db_short == short_url
  end

  test "tries get on unexisting url", %{conn: conn} do
    fake_short_hash = "123456"

    response = get(conn, "/#{fake_short_hash}")

    assert %{"error" => "The requested short url does not exist"} =
             response.resp_body |> Poison.decode!()

    assert response.status == 404
  end

  test "generate url and redirect with same parameters", %{conn: conn} do
    original = "http://example.com/about/index.html?uid=123"

    response = post(conn, "api/generate_short_url", fullUrl: original)

    %{"shortUrl" => short_url} = response.resp_body |> Poison.decode!()

    conn = get(conn, "/#{short_url}")

    assert redirected_to(conn) == original
  end

  test "redirect maintaining dynamic parameters", %{conn: conn} do
    original = "http://example.com/about/index.html"

    response = post(conn, "api/generate_short_url", fullUrl: "#{original}?uid=123")

    %{"shortUrl" => short_url} = response.resp_body |> Poison.decode!()

    conn = get(conn, "/#{short_url}?uid=789")

    assert redirected_to(conn) == "#{original}?uid=789"
  end

  test "verify request headers saved", %{conn: conn} do
    original = "http://example.com/about/index.html"

    response = post(conn, "api/generate_short_url", fullUrl: original)

    %{"shortUrl" => short_url} = response.resp_body |> Poison.decode!()

    conn =
      conn
      |> put_req_header("test", "my_key")
      |> get("/#{short_url}")

    assert redirected_to(conn) == original
    assert conn.status == 302

    %Urls{id: url_id} = Repo.get_by(Urls, full_url: original)

    %UrlMetadata{metadata: req_metadata} = Repo.get_by(UrlMetadata, urls_id: url_id)

    assert Map.get(req_metadata, "test") == "my_key"
  end
end
