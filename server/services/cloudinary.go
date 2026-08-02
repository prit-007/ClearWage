package services

import (
	"bytes"
	"context"
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"sort"
	"strings"
	"time"
)

const cloudinaryBaseURL = "https://api.cloudinary.com/v1_1"

type CloudinaryResult struct {
	SecureURL string `json:"secure_url"`
	PublicID  string `json:"public_id"`
}

func cloudinarySignature(params map[string]string, apiSecret string) string {
	keys := make([]string, 0, len(params))
	for k := range params {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	var sb strings.Builder
	for i, k := range keys {
		if i > 0 {
			sb.WriteString("&")
		}
		sb.WriteString(k)
		sb.WriteString("=")
		sb.WriteString(params[k])
	}
	sb.WriteString(apiSecret)
	sum := sha1.Sum([]byte(sb.String()))
	return hex.EncodeToString(sum[:])
}

// UploadToCloudinary uploads raw bytes to Cloudinary and returns the secure URL and public id.
// resourceType must be one of: image, raw, auto. A deterministic publicID lets re-uploads overwrite.
func UploadToCloudinary(ctx context.Context, cloudName, apiKey, apiSecret, folder, publicID, resourceType string, fileBytes []byte, filename string) (*CloudinaryResult, error) {
	if resourceType == "" {
		resourceType = "auto"
	}
	timestamp := fmt.Sprintf("%d", time.Now().Unix())

	params := map[string]string{
		"timestamp": timestamp,
		"folder":    folder,
		"overwrite": "true",
	}
	if publicID != "" {
		params["public_id"] = publicID
	}
	signature := cloudinarySignature(params, apiSecret)

	var buf bytes.Buffer
	mp := multipart.NewWriter(&buf)
	writeField := func(k, v string) error { return mp.WriteField(k, v) }
	if err := writeField("timestamp", timestamp); err != nil {
		return nil, err
	}
	if err := writeField("folder", folder); err != nil {
		return nil, err
	}
	if err := writeField("overwrite", "true"); err != nil {
		return nil, err
	}
	if publicID != "" {
		if err := writeField("public_id", publicID); err != nil {
			return nil, err
		}
	}
	if err := writeField("api_key", apiKey); err != nil {
		return nil, err
	}
	if err := writeField("signature", signature); err != nil {
		return nil, err
	}
	fw, err := mp.CreateFormFile("file", filename)
	if err != nil {
		return nil, err
	}
	if _, err := fw.Write(fileBytes); err != nil {
		return nil, err
	}
	if err := mp.Close(); err != nil {
		return nil, err
	}

	endpoint := fmt.Sprintf("%s/%s/%s/upload", cloudinaryBaseURL, cloudName, resourceType)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, &buf)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", mp.FormDataContentType())

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("cloudinary upload request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("cloudinary upload failed (%d): %s", resp.StatusCode, string(body))
	}

	var result CloudinaryResult
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("cloudinary upload response: %w", err)
	}
	return &result, nil
}

// DeleteFromCloudinary removes an asset by public id.
// resourceType must be one of: image, raw.
func DeleteFromCloudinary(ctx context.Context, cloudName, apiKey, apiSecret, publicID, resourceType string) error {
	if publicID == "" {
		return nil
	}
	if resourceType == "" {
		resourceType = "image"
	}
	timestamp := fmt.Sprintf("%d", time.Now().Unix())
	params := map[string]string{
		"timestamp": timestamp,
		"public_id": publicID,
	}
	signature := cloudinarySignature(params, apiSecret)

	form := fmt.Sprintf("timestamp=%s&public_id=%s&api_key=%s&signature=%s",
		timestamp, publicID, apiKey, signature)
	endpoint := fmt.Sprintf("%s/%s/%s/destroy", cloudinaryBaseURL, cloudName, resourceType)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, strings.NewReader(form))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return fmt.Errorf("cloudinary destroy request: %w", err)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("cloudinary destroy failed (%d): %s", resp.StatusCode, string(body))
	}
	return nil
}
