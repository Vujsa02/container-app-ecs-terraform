package metrics

import "sync/atomic"

// Collector tracks application-level metrics using lock-free atomics.
// Safe for concurrent use from multiple goroutines.
type Collector struct {
	totalRequests atomic.Int64
}

// NewCollector returns an initialised Collector.
func NewCollector() *Collector {
	return &Collector{}
}

// IncRequests atomically increments the total request count.
func (c *Collector) IncRequests() {
	c.totalRequests.Add(1)
}

// TotalRequests returns the current total request count.
func (c *Collector) TotalRequests() int64 {
	return c.totalRequests.Load()
}
