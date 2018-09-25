FROM elixir:1.7.2

ENV SERVERDIR /opt/server

ARG MIX_ENV=dev

WORKDIR ${SERVERDIR}

ADD . ${SERVERDIR}

RUN apt-get update && apt-get install -y jq inotify-tools curl \
    && mix local.hex --force \
    && mix local.rebar \
    && mix deps.get \
    && mix deps.compile

EXPOSE 4000

ENTRYPOINT ["./scripts/entrypoint.sh"]

CMD ["elixir", "-S", "mix", "phx.server"]
