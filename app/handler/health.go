package handler

import (
	"encoding/json"
	"net/http"
	"time"
)

// healthResponse is the JSON shape returned by /health.
type healthResponse struct {
	Status    string `json:"status"`
	Timestamp string `json:"timestamp"`
}

// Health returns a 200 with the current server status and UTC timestamp.
func Health(w http.ResponseWriter, _ *http.Request) {
	resp := healthResponse{
		Status:    "ok",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(resp)
}
