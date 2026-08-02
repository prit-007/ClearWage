package cli

import (
	"context"
	"database/sql"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/postgres"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/rs/zerolog"
	"github.com/spf13/cobra"

	"github.com/vivek-app/vivek_app/config"
	ctrl "github.com/vivek-app/vivek_app/controllers/api/v1"
	mw "github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/repositories"
	"github.com/vivek-app/vivek_app/services"
)

func GetAPICommandDef(cfg config.AppConfig, logger *zerolog.Logger) cobra.Command {
	apiCommand := cobra.Command{
		Use:   "api",
		Short: "To start api",
		Long:  `To start api`,
		RunE: func(cmd *cobra.Command, args []string) error {
			sqlDB, err := sql.Open("pgx", cfg.DB.ConnectionString())
			if err != nil {
				return err
			}
			defer sqlDB.Close()

			goquDB := goqu.Dialect("postgres").DB(sqlDB)
			querier := repositories.NewGoquQuerier(goquDB)

			r := chi.NewRouter()

			r.Use(mw.RequestLogger(logger))
			r.Use(middleware.Recoverer)
			r.Use(mw.LimitBodySize(5 << 20))
			r.Use(cors.Handler(cors.Options{
				AllowedOrigins:   []string{cfg.AllowedOrigin},
				AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
				AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
				AllowCredentials: false,
				MaxAge:           300,
			}))

			r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(http.StatusOK)
				w.Write([]byte("ok"))
			})

			r.Get("/swagger", func(w http.ResponseWriter, r *http.Request) {
				http.ServeFile(w, r, "./docs/index.html")
			})

			r.Get("/swagger.json", func(w http.ResponseWriter, r *http.Request) {
				http.ServeFile(w, r, "./docs/swagger.json")
			})

			authCtrl, err := ctrl.NewAuthController(querier, logger, cfg)
			if err != nil {
				return err
			}
			r.Route("/api/v1/auth", func(r chi.Router) {
				r.Use(mw.RateLimit(10, time.Minute))
				r.Post("/firebase-login", authCtrl.LoginWithFirebase)
				r.Post("/register", authCtrl.Register)
			})

			shiftCtrl := ctrl.NewShiftController(services.NewShiftService(querier), logger, cfg)
			uploadCtrl := ctrl.NewUploadController(services.NewStaffService(querier), logger, cfg)
			staffCtrl := ctrl.NewStaffController(services.NewStaffService(querier), logger, cfg)
			r.Route("/api/v1/staff", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Get("/", staffCtrl.List)
				r.Post("/", staffCtrl.Create)
				r.Get("/{id}", staffCtrl.Get)
				r.Put("/{id}", staffCtrl.Update)
				r.Delete("/{id}", staffCtrl.Delete)
				r.Post("/{id}/upload-photo", uploadCtrl.UploadPhoto)
				r.Get("/{id}/documents", uploadCtrl.ListDocuments)
				r.Post("/{id}/documents/{type}", uploadCtrl.UploadDocument)
				r.Delete("/{id}/documents/{type}", uploadCtrl.DeleteDocument)
				r.Get("/{id}/profile", staffCtrl.Profile)
				r.Put("/{id}/manager", staffCtrl.AssignManager)
				r.Put("/{id}/default-shift", shiftCtrl.AssignDefaultShift)
			})

			meCtrl := ctrl.NewMeController(
				services.NewStaffService(querier),
				services.NewAttendanceService(querier),
				services.NewLedgerService(querier),
				services.NewPayrollService(querier),
				services.NewAdvanceRequestService(querier),
				logger, cfg,
			)
			r.Route("/api/v1/me", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Get("/", meCtrl.Profile)
				r.Get("/attendance", meCtrl.Attendance)
				r.Get("/ledger", meCtrl.Ledger)
				r.Get("/payslip", meCtrl.Payslip)
				r.Post("/advance-request", meCtrl.RequestAdvance)
			})

			r.Route("/api/v1/shifts", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Get("/", shiftCtrl.List)
				r.Post("/", shiftCtrl.Create)
				r.Get("/{id}", shiftCtrl.Get)
				r.Put("/{id}", shiftCtrl.Update)
				r.Delete("/{id}", shiftCtrl.Delete)
			})

			attCtrl := ctrl.NewAttendanceController(services.NewAttendanceService(querier), logger, cfg)
			r.Route("/api/v1/attendance", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Get("/", attCtrl.ListByDate)
				r.Get("/{id}", attCtrl.ListByEmployee)
				r.Post("/", attCtrl.Create)
				r.Put("/{id}", attCtrl.Update)
				r.Post("/bulk", attCtrl.BulkUpsert)
				r.Post("/lock", attCtrl.LockMonth)
			})

			ledgerCtrl := ctrl.NewLedgerController(services.NewLedgerService(querier), logger, cfg)
			r.Route("/api/v1/ledger", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Post("/", ledgerCtrl.CreateEntry)
				r.Get("/", ledgerCtrl.ListByTenant)
				r.Get("/total-outstanding", ledgerCtrl.GetTotalOutstanding)
				r.Get("/{id}", ledgerCtrl.ListByEmployee)
				r.Get("/{id}/balance", ledgerCtrl.GetBalance)
				r.Post("/{id}/settle", ledgerCtrl.SettleAccount)
			})

			syncCtrl := ctrl.NewSyncQueueController(services.NewSyncQueueService(querier), logger, cfg)
			r.Route("/api/v1/sync", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Post("/", syncCtrl.CreateEvent)
				r.Get("/pending", syncCtrl.ListPending)
				r.Put("/status", syncCtrl.UpdateStatus)
			})

			holidayCtrl := ctrl.NewHolidayController(services.NewHolidayService(querier), logger, cfg)
			r.Route("/api/v1/holidays", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Post("/", holidayCtrl.Create)
				r.Get("/", holidayCtrl.List)
				r.Delete("/{id}", holidayCtrl.Delete)
			})

			leavePolicyCtrl := ctrl.NewLeavePolicyController(services.NewLeavePolicyService(querier), logger, cfg)
			r.Route("/api/v1/leave-policies", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Put("/", leavePolicyCtrl.Upsert)
				r.Get("/", leavePolicyCtrl.Get)
			})

			reportCtrl := ctrl.NewReportController(services.NewReportService(querier), logger, cfg)
			r.Route("/api/v1/reports", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Get("/daily", reportCtrl.DailySummary)
				r.Get("/employee-monthly", reportCtrl.EmployeeMonthly)
				r.Get("/wage-bill-trends", reportCtrl.WageBillTrends)
				r.Get("/defaulters", reportCtrl.DefaultersList)
				r.Get("/attendance-trends", reportCtrl.AttendanceTrends)
				r.Get("/export", reportCtrl.ExportCSV)
			})

			r.With(mw.AuthMiddleware(cfg), mw.TenantMiddleware()).Delete("/api/v1/auth/account", authCtrl.DeleteAccount)

			dashCtrl := ctrl.NewDashboardController(services.NewDashboardService(querier), logger, cfg)
			r.Route("/api/v1/dashboard", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Get("/", dashCtrl.Get)
			})

			advReqCtrl := ctrl.NewAdvanceRequestController(services.NewAdvanceRequestService(querier), logger, cfg)
			r.Route("/api/v1/advance-requests", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Post("/", advReqCtrl.Create)
				r.Get("/", advReqCtrl.List)
				r.Put("/{id}/approve", advReqCtrl.Approve)
				r.Put("/{id}/deny", advReqCtrl.Deny)
			})

			r.With(mw.AuthMiddleware(cfg), mw.TenantMiddleware()).Get("/uploads/{file}", uploadCtrl.ServeFile)

			payrollCtrl := ctrl.NewPayrollController(services.NewPayrollService(querier), logger, cfg)
			r.Route("/api/v1/payroll", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Post("/calculate", payrollCtrl.Calculate)
				r.Post("/payslip", payrollCtrl.GeneratePayslip)
				r.Post("/lock", payrollCtrl.LockMonth)
			})

			settingsCtrl := ctrl.NewSettingsController(services.NewSettingsService(querier), logger, cfg)
			r.Route("/api/v1/settings/payroll", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Get("/", settingsCtrl.GetPayrollSettings)
				r.Put("/", settingsCtrl.UpsertPayrollSettings)
			})

			srv := &http.Server{
				Addr:         cfg.Port,
				Handler:      r,
				ReadTimeout:  10 * time.Second,
				WriteTimeout: 10 * time.Second,
				IdleTimeout:  30 * time.Second,
			}

			go func() {
				logger.Info().Str("addr", srv.Addr).Msg("Server listening")
				if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
					logger.Fatal().Err(err).Msg("Server failed")
				}
			}()

			quit := make(chan os.Signal, 1)
			signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
			<-quit

			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()

			if err := srv.Shutdown(ctx); err != nil {
				logger.Fatal().Err(err).Msg("Server shutdown failed")
			}

			logger.Info().Msg("Server stopped")
			return nil
		},
	}

	return apiCommand
}
