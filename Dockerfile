FROM elixir:1.4

ADD . /app

WORKDIR /app
RUN mix local.hex --force \
    && mix local.rebar --force \
    && rebar3 update \
    && mix deps.get \
    && mix deps.compile \
    && mix compile

CMD ["mix", "run", "--no-halt"]