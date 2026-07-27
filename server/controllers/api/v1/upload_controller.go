package v1

import (
	"crypto/rand"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
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
	os.MkdirAll(uploadDir, 0755)
	return &UploadController{
		staffService: staffService,
		logger:       logger,
		config:       cfg,
		uploadDir:    uploadDir,
	}
}

const maxUploadSize = 5 << 20

func (c *UploadController) UploadPhoto(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	employeeID := chi.URLParam(r, "id")

	r.Body = http.MaxBytesReader(w, r.Body, maxUploadSize)
	if err := r.ParseMultipartForm(maxUploadSize); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "file too large or invalid multipart form")
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "file field is required")
		return
	}
	defer file.Close()

	ext := filepath.Ext(header.Filename)
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" {
		utils.JSONFail(w, http.StatusBadRequest, "only .jpg, .jpeg, .png files are allowed")
		return
	}

	n, _ := rand.Int(rand.Reader, big.NewInt(1<<62))
	filename := fmt.Sprintf("%s-%d%s", employeeID, n.Int64(), ext)
	destPath := filepath.Join(c.uploadDir, filename)

	dst, err := os.Create(destPath)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to create file")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to save file")
		return
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		c.logger.Error().Err(err).Msg("failed to write file")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to save file")
		return
	}

	photoURL := fmt.Sprintf("/uploads/%s", filename)
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

func (c *UploadController) ServeFile(w http.ResponseWriter, r *http.Request) {
	file := chi.URLParam(r, "file")
	absPath, _ := filepath.Abs(filepath.Join(c.uploadDir, file))
	absDir, _ := filepath.Abs(c.uploadDir)
	if !strings.HasPrefix(absPath, absDir) {
		http.Error(w, "Forbidden", http.StatusForbidden)
		return
	}
	http.ServeFile(w, r, absPath)
}
