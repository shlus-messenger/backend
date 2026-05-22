FROM elixir:1.18.3-alpine AS builder

RUN apk add --no-cache \
    build-base \
    git \
    openssl-dev \
    postgresql-client \
    postgresql-dev

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY config ./config
COPY lib ./lib
COPY priv ./priv

ENV MIX_ENV=prod
RUN mix compile
RUN mix phx.digest
RUN mix release --overwrite

FROM alpine:3.21

RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    postgresql-client \
    bash \
    libstdc++

RUN addgroup -g 1000 -S chat && \
    adduser -S chat -u 1000 -G chat

WORKDIR /app

COPY --from=builder --chown=chat:chat /app/_build/prod/rel/chat ./

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER chat

EXPOSE 4000

ENV PORT=4000
ENV MIX_ENV=prod

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bin/chat", "start"]