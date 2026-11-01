package utils

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestJSONSuccess(t *testing.T) {
	w := httptest.NewRecorder()
	JSONSuccess(w, http.StatusOK, map[string]string{"key": "value"})

	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}
	if ct := w.Header().Get("Content-Type"); ct != "application/json" {
		t.Errorf("expected Content-Type application/json, got %s", ct)
	}

	var resp Response
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to unmarshal response: %v", err)
	}
	if resp.Status != "success" {
		t.Errorf("expected status 'success', got %s", resp.Status)
	}
	if resp.Message != "" {
		t.Errorf("expected empty message, got %s", resp.Message)
	}
}

func TestJSONSuccessNilData(t *testing.T) {
	w := httptest.NewRecorder()
	JSONSuccess(w, http.StatusCreated, nil)

	var resp Response
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}
	if resp.Status != "success" {
		t.Errorf("expected 'success', got %s", resp.Status)
	}
}

func TestJSONFail(t *testing.T) {
	w := httptest.NewRecorder()
	JSONFail(w, http.StatusBadRequest, "invalid input")

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}

	var resp Response
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}
	if resp.Status != "fail" {
		t.Errorf("expected 'fail', got %s", resp.Status)
	}
	if resp.Message != "invalid input" {
		t.Errorf("expected 'invalid input', got %s", resp.Message)
	}
}

func TestJSONError(t *testing.T) {
	w := httptest.NewRecorder()
	JSONError(w, http.StatusInternalServerError, "server error")

	if w.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d", w.Code)
	}

	var resp Response
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}
	if resp.Status != "error" {
		t.Errorf("expected 'error', got %s", resp.Status)
	}
	if resp.Message != "server error" {
		t.Errorf("expected 'server error', got %s", resp.Message)
	}
}

func TestJSONSuccessDataOmittedWhenNil(t *testing.T) {
	w := httptest.NewRecorder()
	JSONSuccess(w, http.StatusOK, nil)

	var resp map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}
	if _, exists := resp["data"]; exists {
		t.Error("expected 'data' field to be omitted when nil")
	}
}

func TestJSONFailMessageOmittedWhenEmpty(t *testing.T) {
	w := httptest.NewRecorder()
	JSONFail(w, http.StatusBadRequest, "")

	var resp map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}
	if _, exists := resp["message"]; exists {
		t.Error("expected 'message' field to be omitted when empty")
	}
}
