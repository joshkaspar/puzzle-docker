# Puzzle (https://github.com/sidhant947/puzzle) — Flutter web build served by nginx.
# Upstream ships no web release or image, so this builds from source at a
# pinned commit. Bump PUZZLE_REF deliberately after reviewing upstream changes.

ARG FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:stable

FROM ${FLUTTER_IMAGE} AS build
ARG PUZZLE_REPO=https://github.com/sidhant947/puzzle.git
ARG PUZZLE_REF=3e70679e51509bd669660b5a4556942fba48321a
WORKDIR /src
RUN git init -q . \
 && git remote add origin "$PUZZLE_REPO" \
 && git fetch -q --depth 1 origin "$PUZZLE_REF" \
 && git checkout -q FETCH_HEAD
RUN flutter config --no-analytics --enable-web \
 && flutter pub get \
 && flutter build web --release --base-href /

FROM nginx:1.27-alpine
LABEL org.opencontainers.image.source="https://github.com/joshkaspar/puzzle-docker" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.title="puzzle" \
      org.opencontainers.image.description="Puzzle (sidhant947/puzzle) Flutter web build served by nginx"
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/build/web /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=60s --timeout=5s CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
