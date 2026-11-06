# Puzzle — Flutter web build served by nginx. Built from the fork
# joshkaspar/Puzzle (upstream sidhant947/puzzle plus the Train Tracks work on
# its train-tracks branch), at a pinned commit. Upstream ships no web release or
# image. Bump PUZZLE_REF deliberately.
# The nginx base tracks the stable line (even minor: 1.30, 1.32, ...).

ARG FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:stable

FROM ${FLUTTER_IMAGE} AS build
ARG PUZZLE_REPO=https://github.com/joshkaspar/Puzzle.git
ARG PUZZLE_REF=e546bf49aef763907bbc7deb2433249a139357f9
WORKDIR /src
RUN git init -q . \
 && git remote add origin "$PUZZLE_REPO" \
 && git fetch -q --depth 1 origin "$PUZZLE_REF" \
 && git checkout -q FETCH_HEAD
RUN flutter config --no-analytics --enable-web \
 && flutter pub get \
 && flutter build web --release --base-href /

FROM nginx:1.30-alpine
LABEL org.opencontainers.image.source="https://github.com/joshkaspar/puzzle-docker" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.title="puzzle" \
      org.opencontainers.image.description="Puzzle (joshkaspar/Puzzle, a fork of sidhant947/puzzle) Flutter web build served by nginx"
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/build/web /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=60s --timeout=5s CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
