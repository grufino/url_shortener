# UrlShortener

Simple Url shortener in Elixir

### Installation / Setup

- For dev environments, it is recommended to use docker-compose, that references to a Postgres image, without requiring to install or use any existing database, leaving to docker to resolve this:
`docker-compose up` sets up the environment with application on port 4000 and db on 5432
`docker-compose down` kills containers and cleans generated data (does not delete images).

- For production environments, please point to a real database and change prod.exs config, then build and run the docker image.

- To run tests, you need to set `MIX_ENV` environment variable to `test`, and then run `mix test`. If using docker-compose the command should be run inside the url_shortener container. Example already setting the env var for this execution: 

`MIX_ENV=test mix test`

### Business rules implemented

- RESTful endpoint to generate a short hash representing a URL in the same API
- Unique shortened url for each long URL
- Shortened url expiration in 1 month without interaction
- Dynamic parameters for existing and new parameters
- All requests are tracked and all request headers are stored related to a single link, in a queryable fashion for analytics purpose.

### Architecture

- One POST endpoint to create the URL and reply with a JSON containing the short key hash: `/api/generate_short_url`
- One generic GET endpoint to access the long url through the hash created on POST enpoint `/SHORT_HASH`
- Each POST of a new long url generates a new line in `urls` table, with a new short hash and validity to one month later. If the hash already exists it only updates the validity and returns the already created hash.
- Each GET of an existing short hash will generate a new registry in `url_metadata` table, associated by the urls_id, so in order to query by a long url, for example, it is necessary to JOIN the two.
- The metadata (request headers) was saved as a json map (jsonb structure in postgres, map in elixir), this is to allow flexibility in the request headers, as they may change a lot depending on the client.
- Example query for the URL `http://google.com/` see all the metadata generated:
select metadata from url_metadata um, urls u
where um.urls_id = u.id
and u.full_url = 'http://google.com/'
- Example query to select all requests hitting localhost, querying the JSON inside the table:
select * from url_metadata
WHERE metadata @> '{"host": "localhost:4000"}'