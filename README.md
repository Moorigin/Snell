# Snell Docker Image

This image downloads the Snell Server binary at container startup and runs it with a mounted config file.

The image does not generate `snell-server.conf`. You keep the config on the host and mount it into the container.

## Build Locally

```sh
docker build -t snell:local .
```

## Run With Compose

`docker-compose.yml` uses this image name:

```yaml
image: ghcr.io/moorigin/snell:latest
```

The Snell config is mounted from:

```text
./config/snell.conf
```

Example config:

```ini
[snell-server]
listen = [::]:10086
psk = 6Svv170y5XgGNwUeket+0w==
ipv6 = true
```

Run:

```sh
docker compose up -d
```

## IPv4 And IPv6 Listening

The example config uses:

```ini
listen = [::]:10086
```

On Linux hosts where `net.ipv6.bindv6only = 0`, this listens on both IPv6 and IPv4-mapped addresses. This is the usual default.

Check it with:

```sh
sysctl net.ipv6.bindv6only
```

If it returns `net.ipv6.bindv6only = 1`, change it to `0` on the host if you need one listener to cover both IPv4 and IPv6.

## Upgrade Snell

Change only this value in `docker-compose.yml`:

```yaml
SNELL_URL: "https://dl.nssurge.com/snell/snell-server-v5.0.1-linux-amd64.zip"
```

Then recreate the container:

```sh
docker compose up -d --force-recreate
```

The entrypoint compares the new URL with the cached URL. If it changed, it downloads the new zip and replaces `/opt/snell/bin/snell-server`.

## Publish to GitHub Container Registry

Push these files to a GitHub repository. The workflow in `.github/workflows/docker.yml` publishes:

- `ghcr.io/<your-github-username>/snell:latest` on pushes to `main`
- `ghcr.io/<your-github-username>/snell:vX.Y.Z` on Git tags
- `ghcr.io/<your-github-username>/snell:sha-<commit>` for each build

Manual publish:

```sh
echo "$GITHUB_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
docker buildx create --use
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/YOUR_GITHUB_USERNAME/snell:latest \
  --push .
```
