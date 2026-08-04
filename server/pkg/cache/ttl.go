package cache

import (
	"sync"
	"time"
)

type entry struct {
	value     interface{}
	expiresAt time.Time
}

// TTL is a lightweight, concurrency-safe, in-memory read cache.
type TTL struct {
	ttl    time.Duration
	items  sync.Map
	stopCh chan struct{}
}

// New creates a TTL cache that evicts expired entries every sweep interval.
func New(ttl time.Duration) *TTL {
	c := &TTL{ttl: ttl, stopCh: make(chan struct{})}
	go c.sweep()
	return c
}

func (c *TTL) sweep() {
	ticker := time.NewTicker(c.ttl / 2)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			now := time.Now()
			c.items.Range(func(key, value interface{}) bool {
				if e, ok := value.(*entry); ok && now.After(e.expiresAt) {
					c.items.Delete(key)
				}
				return true
			})
		case <-c.stopCh:
			return
		}
	}
}

// Get returns the cached value and true if it exists and is not expired.
func (c *TTL) Get(key string) (interface{}, bool) {
	v, ok := c.items.Load(key)
	if !ok {
		return nil, false
	}
	e := v.(*entry)
	if time.Now().After(e.expiresAt) {
		c.items.Delete(key)
		return nil, false
	}
	return e.value, true
}

// Set stores a value with the cache's default TTL.
func (c *TTL) Set(key string, value interface{}) {
	c.items.Store(key, &entry{
		value:     value,
		expiresAt: time.Now().Add(c.ttl),
	})
}

// Delete removes a key from the cache.
func (c *TTL) Delete(key string) {
	c.items.Delete(key)
}

// Stop halts the background sweep goroutine.
func (c *TTL) Stop() {
	close(c.stopCh)
}
