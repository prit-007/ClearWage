package pkg

import "testing"

func TestHashAndCheckPassword(t *testing.T) {
	password := "test-password-123"

	hash, err := HashPassword(password)
	if err != nil {
		t.Fatalf("HashPassword failed: %v", err)
	}

	if hash == "" {
		t.Fatal("expected non-empty hash")
	}

	if hash == password {
		t.Fatal("hash should not equal plain password")
	}

	if !CheckPassword(password, hash) {
		t.Fatal("CheckPassword should return true for correct password")
	}

	if CheckPassword("wrong-password", hash) {
		t.Fatal("CheckPassword should return false for wrong password")
	}
}

func TestHashIsDifferentEachTime(t *testing.T) {
	password := "same-password"

	hash1, err := HashPassword(password)
	if err != nil {
		t.Fatalf("HashPassword failed: %v", err)
	}

	hash2, err := HashPassword(password)
	if err != nil {
		t.Fatalf("HashPassword failed: %v", err)
	}

	if hash1 == hash2 {
		t.Fatal("bcrypt hashes should be different each time due to random salt")
	}

	if !CheckPassword(password, hash1) {
		t.Fatal("hash1 should verify")
	}

	if !CheckPassword(password, hash2) {
		t.Fatal("hash2 should verify")
	}
}
