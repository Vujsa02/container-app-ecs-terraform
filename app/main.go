package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/Vujsa02/decenter/app/handler"
	"github.com/Vujsa02/decenter/app/middleware"
	"github.com/Vujsa02/decenter/app/metrics"
)

func main() {
	// Self-contained healthcheck mode for Docker HEALTHCHECK (no curl in scratch).
	if len(os.Args) > 1 && os.Args[1] == "-healthcheck" {
		runHealthCheck()
		return
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	collector := metrics.NewCollector()

	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", handler.Health)
	mux.HandleFunc("GET /metrics", handler.Metrics(collector))

	// Middleware chain: logging -> request counting -> router
	wrapped := middleware.Logger(logger,
		middleware.RequestCounter(collector, mux),
	)

	srv := &http.Server{
		Addr:              ":3000",
		Handler:           wrapped,
		ReadTimeout:       5 * time.Second,
		ReadHeaderTimeout: 2 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       120 * time.Second,
		MaxHeaderBytes:    1 << 20, // 1 MB
	}

	// Graceful shutdown on SIGTERM / SIGINT
	done := make(chan os.Signal, 1)
	signal.Notify(done, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		slog.Info("server starting", "addr", srv.Addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("server failed", "error", err)
			os.Exit(1)
		}
	}()

	<-done
	slog.Info("shutting down")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		slog.Error("forced shutdown", "error", err)
		os.Exit(1)
	}

	slog.Info("server stopped")
}

// runHealthCheck makes an HTTP GET to /health and exits 0 on success, 1 on failure.
// Used by Docker HEALTHCHECK so we don't need curl/wget in a scratch image.
func runHealthCheck() {
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://localhost:3000/health")
	if err != nil {
		fmt.Fprintf(os.Stderr, "healthcheck failed: %v\n", err)
		os.Exit(1)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		fmt.Fprintf(os.Stderr, "healthcheck returned status %d\n", resp.StatusCode)
		os.Exit(1)
	}
	os.Exit(0)
}
