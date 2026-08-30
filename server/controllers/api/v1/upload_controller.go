package v1

import (
	"bytes"
	"crypto/rand"
	"errors"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/middlewares"
	"github.com/clearwage/clearwage/repositories"
	"github.com/clearwage/clearwage/services"
	"github.com/clearwage/clearwage/utils"
)

type UploadController struct {
	staffService *services.StaffService
	logger       *zerolog.Logger
	config       config.AppConfig
	uploadDir    string
}

func NewUploadController(staffService *services.StaffService, logger *zerolog.Logger, cfg config.AppConfig) *UploadController {
	uploadDir := "./uploads"
	if d := os.Getenv("UPLOAD_DIR"); d != "" {
		uploadDir = d
	}
	if err := os.MkdirAll(uploadDir, 0700); err != nil {
		logger.Warn().Err(err).Msg("failed to create upload directory")
	}
	return &UploadController{
		staffService: staffService,
		logger:       logger,
		config:       cfg,
		uploadDir:    uploadDir,
	}
}

const maxUploadSize = 5 << 20

// uploadBytes streams the multipart "file" field into memory (bounded by maxUploadSize).
func uploadBytes(r *http.Request) ([]byte, string, error) {
	if err := r.ParseMultipartForm(maxUploadSize); err != nil {
		return nil, "", fmt.Errorf("file too large or invalid multipart form")
	}
	file, header, err := r.FormFile("file")
	if err != nil {
		return nil, "", fmt.Errorf("file field is required")
	}
	defer func() { _ = file.Close() }()
	data, err := io.ReadAll(io.LimitReader(file, maxUploadSize))
	if err != nil {
		return nil, "", err
	}
	return data, header.Filename, nil
}

func (c *UploadController) cloudinaryResourceType(ext string) string {
	if ext == ".pdf" {
		return "raw"
	}
	return "image"
}

func (c *UploadController) UploadPhoto(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	employeeID := chi.URLParam(r, "id")
	claims := middlewares.RequireNonEmployee(w, r.Context())
	if claims == nil {
		return
	}
	if claims.EmployeeID != employeeID {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, maxUploadSize)
	data, filename, err := uploadBytes(r)
	if err != nil {
		utils.JSONFail(w, http.StatusBadRequest, err.Error())
		return
	}

	ext := strings.ToLower(filepath.Ext(filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" {
		utils.JSONFail(w, http.StatusBadRequest, "only .jpg, .jpeg, .png files are allowed")
		return
	}

	var photoURL string
	if c.config.CloudinaryEnabled() {
		cr, upErr := services.UploadToCloudinary(r.Context(),
			c.config.CloudinaryCloudName, c.config.CloudinaryAPIKey, c.config.CloudinaryAPISecret,
			"profiles", "profile/"+employeeID, "image", data, filename)
		if upErr != nil {
			c.logger.Error().Err(upErr).Msg("cloudinary photo upload failed")
			utils.JSONError(w, http.StatusInternalServerError, "Failed to upload photo")
			return
		}
		photoURL = cr.SecureURL
	} else {
		n, randErr := rand.Int(rand.Reader, big.NewInt(1<<62))
		if randErr != nil {
			c.logger.Error().Err(randErr).Msg("failed to generate random number")
			utils.JSONError(w, http.StatusInternalServerError, "Internal error")
			return
		}
		localName := fmt.Sprintf("%s-%d%s", employeeID, n.Int64(), ext)
		tenantDir := filepath.Join(c.uploadDir, tenantID)
		if mkdirErr := os.MkdirAll(tenantDir, 0700); mkdirErr != nil {
			c.logger.Warn().Err(mkdirErr).Str("dir", tenantDir).Msg("failed to create tenant upload directory")
		}
		destPath := filepath.Join(tenantDir, localName)
		if saveErr := c.saveFile(destPath, bytes.NewReader(data)); saveErr != nil {
			c.logger.Error().Err(saveErr).Msg("failed to save photo")
			utils.JSONError(w, http.StatusInternalServerError, "Failed to save file")
			return
		}
		photoURL = "/uploads/" + tenantID + "/" + localName
	}

	emp, err := c.staffService.UpdatePhotoURL(r.Context(), employeeID, tenantID, photoURL)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to update photo URL")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to update employee photo")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]interface{}{
		"photo_url": photoURL,
		"employee":  emp,
	})
}

// UploadDocument stores a KYC document image or PDF for an employee.
// One document per doc_type (aadhaar | pan | bank); uploading replaces any existing file.
func (c *UploadController) UploadDocument(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.RequireNonEmployee(w, r.Context())
	if claims == nil {
		return
	}

	employeeID := chi.URLParam(r, "id")
	docType := chi.URLParam(r, "type")
	if docType != "aadhaar" && docType != "pan" && docType != "bank" {
		utils.JSONFail(w, http.StatusBadRequest, "doc_type must be one of: aadhaar, pan, bank")
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, maxUploadSize)
	data, filename, err := uploadBytes(r)
	if err != nil {
		utils.JSONFail(w, http.StatusBadRequest, err.Error())
		return
	}

	ext := strings.ToLower(filepath.Ext(filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".pdf" {
		utils.JSONFail(w, http.StatusBadRequest, "only .jpg, .jpeg, .png, .pdf files are allowed")
		return
	}

	existing, getErr := c.staffService.GetDocumentByType(r.Context(), tenantID, employeeID, docType)
	existingOK := getErr == nil

	var filePath string
	var publicID *string
	if c.config.CloudinaryEnabled() {
		pid := fmt.Sprintf("kyc/%s/%s", employeeID, docType)
		cr, upErr := services.UploadToCloudinary(r.Context(),
			c.config.CloudinaryCloudName, c.config.CloudinaryAPIKey, c.config.CloudinaryAPISecret,
			"kyc/"+employeeID, pid, c.cloudinaryResourceType(ext), data, filename)
		if upErr != nil {
			c.logger.Error().Err(upErr).Msg("cloudinary document upload failed")
			utils.JSONError(w, http.StatusInternalServerError, "Failed to upload document")
			return
		}
		filePath = cr.SecureURL
		publicID = &cr.PublicID
	} else {
		if existingOK && existing.FilePath != "" {
			c.removeFile(existing.FilePath)
		}
		n, randErr := rand.Int(rand.Reader, big.NewInt(1<<62))
		if randErr != nil {
			c.logger.Error().Err(randErr).Msg("failed to generate random number")
			utils.JSONError(w, http.StatusInternalServerError, "Internal error")
			return
		}
		localName := fmt.Sprintf("%s-%s-%d%s", employeeID, docType, n.Int64(), ext)
		tenantDir := filepath.Join(c.uploadDir, tenantID)
		if mkdirErr := os.MkdirAll(tenantDir, 0700); mkdirErr != nil {
			c.logger.Warn().Err(mkdirErr).Str("dir", tenantDir).Msg("failed to create tenant upload directory")
		}
		destPath := filepath.Join(tenantDir, localName)
		if saveErr := c.saveFile(destPath, bytes.NewReader(data)); saveErr != nil {
			c.logger.Error().Err(saveErr).Msg("failed to save document")
			utils.JSONError(w, http.StatusInternalServerError, "Failed to save file")
			return
		}
		filePath = "/uploads/" + tenantID + "/" + localName
	}

	originalName := filename
	doc, err := c.staffService.SaveDocument(r.Context(), tenantID, employeeID, docType, filePath, publicID, &originalName)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to save document record")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to save document record")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, doc)
}

// ListDocuments returns all stored documents for an employee.
func (c *UploadController) ListDocuments(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	employeeID := chi.URLParam(r, "id")
	claims := middlewares.RequireNonEmployee(w, r.Context())
	if claims == nil {
		return
	}
	if claims.EmployeeID != employeeID {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	docs, err := c.staffService.ListDocuments(r.Context(), tenantID, employeeID)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list documents")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to list documents")
		return
	}
	utils.JSONSuccess(w, http.StatusOK, docs)
}

// DeleteDocument removes a stored document (record + file).
func (c *UploadController) DeleteDocument(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.RequireNonEmployee(w, r.Context())
	if claims == nil {
		return
	}

	employeeID := chi.URLParam(r, "id")
	docType := chi.URLParam(r, "type")

	existing, err := c.staffService.GetDocumentByType(r.Context(), tenantID, employeeID, docType)
	if err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			utils.JSONFail(w, http.StatusNotFound, "document not found")
			return
		}
		utils.JSONError(w, http.StatusInternalServerError, "Failed to delete document")
		return
	}

	if err := c.staffService.DeleteDocument(r.Context(), tenantID, employeeID, docType); err != nil {
		c.logger.Error().Err(err).Msg("failed to delete document record")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to delete document")
		return
	}

	if c.config.CloudinaryEnabled() {
		if existing.PublicID != nil {
			resourceType := "image"
			if existing.OriginalName != nil {
				resourceType = c.cloudinaryResourceType(strings.ToLower(filepath.Ext(*existing.OriginalName)))
			}
			if err := services.DeleteFromCloudinary(r.Context(),
				c.config.CloudinaryCloudName, c.config.CloudinaryAPIKey, c.config.CloudinaryAPISecret,
				*existing.PublicID, resourceType); err != nil {
				c.logger.Warn().Err(err).Msg("failed to delete cloudinary asset")
			}
		}
	} else {
		c.removeFile(existing.FilePath)
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]string{"message": "document deleted"})
}

func (c *UploadController) saveFile(destPath string, src io.Reader) error {
	dst, err := os.OpenFile(destPath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0600)
	if err != nil {
		return err
	}
	defer func() { _ = dst.Close() }()
	if _, err := io.Copy(dst, src); err != nil {
		return err
	}
	return nil
}

func (c *UploadController) removeFile(filePath string) {
	if filePath == "" {
		return
	}
	cleaned := filepath.Clean(filePath)
	cleaned = strings.TrimPrefix(cleaned, "/uploads/")
	absPath, err := filepath.Abs(filepath.Join(c.uploadDir, cleaned))
	if err != nil {
		return
	}
	absDir, err := filepath.Abs(c.uploadDir)
	if err != nil {
		return
	}
	if strings.HasPrefix(absPath, absDir+"/") || absPath == absDir {
		if err := os.Remove(absPath); err != nil && !os.IsNotExist(err) {
			c.logger.Warn().Err(err).Str("path", absPath).Msg("failed to remove file")
		}
	}
}

func (c *UploadController) ServeFile(w http.ResponseWriter, r *http.Request) {
	file := chi.URLParam(r, "file")
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	tenantDir := filepath.Join(c.uploadDir, tenantID)
	absPath, err := filepath.Abs(filepath.Join(tenantDir, file))
	if err != nil {
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}
	absTenantDir, err := filepath.Abs(tenantDir)
	if err != nil {
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}
	if !strings.HasPrefix(absPath, absTenantDir+"/") && absPath != absTenantDir {
		http.Error(w, "Forbidden", http.StatusForbidden)
		return
	}
	http.ServeFile(w, r, absPath)
}
