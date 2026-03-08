package middleware

import (
	"net/http"

	"github.com/Vujsa02/decenter/app/metrics"
)

// RequestCounter increments the collector for every inbound request.
func RequestCounter(c *metrics.Collector, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		c.IncRequests()
		next.ServeHTTP(w, r)
	})
}
