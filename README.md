# puzzle-docker

A Docker image for [Puzzle](https://github.com/sidhant947/puzzle), a Flutter app with 300+
offline brain games. Upstream ships no Docker image and no web release, so this repo builds
the Flutter web target from source at a pinned commit and serves it with `nginx:1.27-alpine`.

Image: `ghcr.io/joshkaspar/puzzle-docker:<short upstream commit>` (also `:latest`).

## Run it

```sh
cp .env.example .env    # adjust port, bind address, etc.
docker compose up -d
```

Then open `http://<host>:8095` (or whatever `PUZZLE_PORT` you set).

Settings in `.env`:

| Variable | Default | Meaning |
|---|---|---|
| `PUZZLE_TAG` | `3e70679` | Image tag (short upstream commit) |
| `PUZZLE_PORT` | `8095` | Host port |
| `PUZZLE_BIND` | `0.0.0.0` | Host address to bind |
| `PUZZLE_CONTAINER_NAME` | `puzzle` | Container name |
| `PUZZLE_MEM_LIMIT` | `128m` | Memory limit |

There are no volumes. Game progress is stored in each browser's IndexedDB, not on the
server, so there is nothing to back up and progress doesn't sync between devices.

The container runs read-only, with all capabilities dropped except the four nginx needs
(`CHOWN`, `SETUID`, `SETGID`, `NET_BIND_SERVICE`) and `no-new-privileges` set. It only serves
static files.

## Why CI builds the image

GitHub Actions (`.github/workflows/image.yml`) builds and pushes the image on every push to
`main`. The build stage uses `ghcr.io/cirruslabs/flutter:stable`, which is several GB because
it bundles the Android SDK. Building in CI means a host only pulls the final image (nginx plus
the web assets) and never has to store the Flutter image.

You can still build locally: `docker build -t puzzle .`

## Updating

Updates are deliberate, never automatic. The compose file pins a commit tag rather than
`:latest`, so a CI run never changes what a host runs.

1. Review upstream changes, then set `PUZZLE_REF` in the `Dockerfile` to the new full commit.
2. Change the default tag (first 7 characters of the commit) in `docker-compose.yml` and
   `.env.example`.
3. Push to `main` and wait for the workflow to finish.
4. On the host, set `PUZZLE_TAG` in `.env`, then `docker compose pull && docker compose up -d`.

Upstream CI builds on Flutter's `stable` channel with no pinned version, and so does this
repo. If a future stable release breaks the build, pin one with
`--build-arg FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:<version>`.

## License

Puzzle is © its authors and licensed under GPL-3.0. The image contains a build of it, and its
corresponding source is the upstream commit named by `PUZZLE_REF` plus the files in this repo.
The packaging in this repo is also licensed under GPL-3.0 (see `LICENSE`).
