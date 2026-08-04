package cache

import (
	"testing"
	"time"
)

func TestTTL_SetGet(t *testing.T) {
	c := New(50 * time.Millisecond)
	defer c.Stop()

	c.Set("key1", "value1")
	if v, ok := c.Get("key1"); !ok || v != "value1" {
		t.Errorf("expected value1, got %v (ok=%v)", v, ok)
	}
}

func TestTTL_Expiry(t *testing.T) {
	c := New(20 * time.Millisecond)
	defer c.Stop()

	c.Set("key1", "value1")
	time.Sleep(30 * time.Millisecond)

	if _, ok := c.Get("key1"); ok {
		t.Error("expected cache miss after expiry")
	}
}

func TestTTL_Delete(t *testing.T) {
	c := New(50 * time.Millisecond)
	defer c.Stop()

	c.Set("key1", "value1")
	c.Delete("key1")

	if _, ok := c.Get("key1"); ok {
		t.Error("expected cache miss after delete")
	}
}

func TestTTL_Miss(t *testing.T) {
	c := New(50 * time.Millisecond)
	defer c.Stop()

	if _, ok := c.Get("nonexistent"); ok {
		t.Error("expected cache miss")
	}
}

func TestTTL_Overwrite(t *testing.T) {
	c := New(50 * time.Millisecond)
	defer c.Stop()

	c.Set("key1", "old")
	c.Set("key1", "new")

	if v, ok := c.Get("key1"); !ok || v != "new" {
		t.Errorf("expected new, got %v", v)
	}
}
