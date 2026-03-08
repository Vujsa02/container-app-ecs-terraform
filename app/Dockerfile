# ---------- stage 1: build ----------
FROM golang:1.23-alpine AS builder

# Build args for reproducibility & cache-busting if needed
ARG CGO_ENABLED=0
ARG GOOS=linux
ARG GOARCH=amd64

WORKDIR /src

# Cache module downloads separately from source changes
COPY go.mod ./
RUN go mod download

# Copy source and compile a fully static binary
COPY . .
RUN go build \
    -ldflags="-s -w" \
    -trimpath \
    -o /bin/server \
    .

# ---------- stage 2: runtime ----------
# scratch = 0 MB base — no shell, no OS, no attack surface
FROM scratch

# Import CA certs so outbound TLS works if needed later
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy the static binary
COPY --from=builder /bin/server /server

# Expose application port (documentation only)
EXPOSE 3000

# Check /health every 30 s; container is unhealthy after 3 consecutive failures
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/server", "-healthcheck"]

ENTRYPOINT ["/server"]
