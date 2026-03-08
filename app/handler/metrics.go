package handler

import (
	"encoding/json"
	"net/http"

	"github.com/Vujsa02/decenter/app/metrics"
)

// metricsResponse is the JSON shape returned by /metrics.
type metricsResponse struct {
	TotalRequests int64 `json:"total_requests"`
}

// Metrics returns a handler that reports the total request count.
func Metrics(c *metrics.Collector) http.HandlerFunc {
	return func(w http.ResponseWriter, _ *http.Request) {
		resp := metricsResponse{
			TotalRequests: c.TotalRequests(),
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(resp)
	}
}
