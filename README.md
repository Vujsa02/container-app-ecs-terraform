# Decenter App

Lightweight Go HTTP server exposing `/health` and `/metrics`, packaged in a minimal Docker image and shipped via GitHub Actions to GHCR.

## Run locally (requires Go 1.23+)

```bash
cd app
go run .
# http://localhost:3000/health
# http://localhost:3000/metrics
```

## Run with Docker

```bash
cd app
docker build -t decenter-app .
docker run -d -p 80:3000 --name decenter decenter-app
```

The application is now reachable at `http://localhost/health` (port 80 → 3000).

Check container health status:

```bash
docker inspect --format='{{.State.Health.Status}}' decenter
```

## Endpoints

| Path       | Method | Description                                 |
|------------|--------|---------------------------------------------|
| `/health`  | GET    | `{"status":"ok","timestamp":"…"}`           |
| `/metrics` | GET    | `{"total_requests": N}`                     |

## CI/CD

On every push to `main`, the GitHub Actions workflow (`.github/workflows/ci.yml`) builds the Docker image and pushes it to GHCR with a `latest` tag and a commit-SHA tag.

To pull the image:

```bash
docker pull ghcr.io/<owner>/decenter/app:latest
docker run -d -p 80:3000 ghcr.io/<owner>/decenter/app:latest
```

Replace `<owner>` with the GitHub username or organisation.

## Design decisions

### Why Go standard library only

Zero external dependencies means zero transitive CVEs, no vendoring headaches, and the binary compiles in seconds. `net/http` in Go 1.22+ supports method-scoped routing (`GET /health`) natively, so a framework adds nothing here.

### Why `scratch` base image

The final image contains exactly one file: the statically-linked binary (~6 MB). No shell, no package manager, no OS — the attack surface is effectively zero. CA certificates are copied from the builder stage so outbound TLS still works if the app ever needs it.

### Self-contained healthcheck

`scratch` has no `curl` or `wget`. Instead the binary accepts a `-healthcheck` flag that makes an HTTP call to `localhost:3000/health` and exits 0/1. Same binary, no extra tooling.

### Atomic request counter

`sync/atomic.Int64` — lock-free, no mutex contention under load. The counter is wrapped in a `metrics.Collector` struct so it can be extended later (e.g., per-endpoint counters, latency histograms) without changing the handler signatures.

### Middleware pattern

Logging and request counting are middleware, not inline in handlers. Adding rate limiting, auth, or CORS later is one function call in the chain.

### Graceful shutdown

The server listens for SIGTERM/SIGINT and drains in-flight requests (10 s timeout). This prevents dropped connections during container stops or rolling deployments.

### HTTP server timeouts

`ReadTimeout`, `ReadHeaderTimeout`, `WriteTimeout`, and `IdleTimeout` are all set explicitly. Without them the default Go server has no timeouts at all — a trivial slowloris attack would exhaust file descriptors.

### Docker layer caching

`go.mod` is copied and resolved before the source code. Changing a handler doesn't re-download modules.

### CI caching

`cache-from: type=gha` + `cache-to: type=gha,mode=max` stores Docker layer cache in GitHub Actions cache. Rebuilds that only touch Go source skip the base-image and module-download layers entirely.

## Notes

- The `/metrics` counter includes requests to all endpoints (including `/health` and `/metrics` itself). If you want to exclude healthcheck probes, add a path filter in the counter middleware.
- The `-ldflags="-s -w"` and `-trimpath` flags strip debug symbols and build paths from the binary, reducing size and preventing information leakage.
