# Go App

Simple Go HTTP server with `/health` and `/metrics` endpoints. Runs on port 3000, packaged in a scratch Docker image, pushed to GHCR via GitHub Actions.

## How to run

Locally (requires Go 1.23+):

```bash
cd app
go run .
```

With Docker:

```bash
cd app
docker build -t decenter-app .
docker run -d -p 80:3000 --name decenter decenter-app
```

App is reachable at `http://localhost/health` (port 80 maps to 3000 inside the container).

To check container health: `docker inspect --format='{{.State.Health.Status}}' decenter`

## Endpoints

- `GET /health` - returns `{"status": "ok", "timestamp": "..."}`.
- `GET /metrics` - returns `{"total_requests": N}`, counting all requests since startup (including `/health` and `/metrics` itself).

## CI/CD

On push to `main` (when files inside `app/` change), the GitHub Actions workflow builds the image and pushes it to GHCR with a `latest` tag and a commit-SHA tag. Build layers are cached via GitHub Actions cache so rebuilds that only touch Go source skip the base image and module download steps.

## Design decisions

### No external dependencies

The app uses only the Go standard library. Zero third-party modules means no transitive CVEs, no vendoring, and no `go.sum` file (there's nothing to checksum). Go 1.22+ added method-scoped routing to `net/http` (`GET /health`), so a framework would add nothing.

### Scratch base image

The final image is a single static binary (~6 MB) on top of `scratch` - no shell, no OS, no package manager. Attack surface is effectively zero. CA certificates are copied from the builder stage so outbound TLS works if needed later.

### Self-contained healthcheck

`scratch` has no `curl` or `wget`. The binary itself accepts a `-healthcheck` flag - it makes an HTTP call to `localhost:3000/health` and exits 0 or 1. Same binary, no extra tooling needed in the image.

### Middleware pattern

Logging and request counting are implemented as middleware, not inline in handlers. This makes it easy to add rate limiting, auth, or CORS later - just one more function in the chain.

### Atomic counter

The request counter uses `sync/atomic.Int64` - lock-free with no mutex contention. It's wrapped in a `metrics.Collector` struct so it can be extended with per-endpoint counters or latency histograms without changing handler signatures.

### Graceful shutdown

The server catches SIGTERM/SIGINT and drains in-flight requests with a 10-second timeout. This prevents dropped connections during container stops or rolling deployments in ECS.

### HTTP server timeouts

`ReadTimeout`, `ReadHeaderTimeout`, `WriteTimeout`, and `IdleTimeout` are all set explicitly. Without them Go's default server has no timeouts - a slowloris attack would exhaust file descriptors.

### Docker layer caching

`go.mod` is copied and resolved before the source code. Changing a handler doesn't re-download modules.

### Build flags

`-ldflags="-s -w"` strips debug symbols, `-trimpath` removes local build paths from the binary. Both reduce image size and prevent information leakage.
