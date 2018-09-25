use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :url_shortener, UrlShortenerWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :url_shortener, UrlShortener.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "postgres",
  hostname: "postgres",
  pool_size: 10,
  pool: Ecto.Adapters.SQL.Sandbox


config :url_shortener, time_now: UrlShortener.TimeNowMock
config :url_shortener, task: UrlShortener.TaskMock
