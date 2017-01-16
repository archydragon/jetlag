FROM elixir:1.4

RUN mkdir -p /app
ADD . /app

WORKDIR /app
RUN mix local.hex --force
RUN mix local.rebar --force
RUN rebar3 update
RUN mix deps.get
RUN mix deps.compile
RUN mix compile

CMD ["mix", "run", "--no-halt"]