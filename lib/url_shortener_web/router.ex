defmodule UrlShortenerWeb.Router do
  use UrlShortenerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :redirect_url do
    plug(:accepts, ["html", "json"])
    plug(:fetch_session)
    plug(:fetch_flash)
  end

  scope "/api", UrlShortenerWeb do
    pipe_through :api
    post("/generate_short_url", GenerateUrlController, :generate_short_url)
  end

  scope "/", UrlShortenerWeb do
    pipe_through :redirect_url
    get("/:shortUrl", RedirectUrlController, :redirect_url)
  end
end
