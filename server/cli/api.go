package cli

import (
	"context"
	"crypto/subtle"
	"database/sql"
	"fmt"
	"net/http"
	"net/http/pprof"
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

	"github.com/clearwage/clearwage/config"
	ctrl "github.com/clearwage/clearwage/controllers/api/v1"
	mw "github.com/clearwage/clearwage/middlewares"
	"github.com/clearwage/clearwage/repositories"
	sqldb "github.com/clearwage/clearwage/repositories/db"
	"github.com/clearwage/clearwage/services"
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

			sqlDB.SetMaxOpenConns(cfg.DB.MaxConns)
			sqlDB.SetMaxIdleConns(cfg.DB.MaxIdleConns)
			sqlDB.SetConnMaxLifetime(time.Duration(cfg.DB.ConnMaxLifetimeMinutes) * time.Minute)
			sqlDB.SetConnMaxIdleTime(time.Duration(cfg.DB.ConnMaxIdleTimeMinutes) * time.Minute)

			goquDB := goqu.Dialect("postgres").DB(sqlDB)
			dbQueries := sqldb.New(sqlDB)
			querier := repositories.NewGoquQuerierWithSQL(goquDB, sqlDB, dbQueries)

		services.SetActivityLogger(*logger)

		r := chi.NewRouter()

		r.Use(mw.RequestID)
		r.Use(mw.RequestLogger(logger))
		r.Use(middleware.Recoverer)
		r.Use(mw.LimitBodySize(int64(cfg.BodyLimitMB) << 20))
		r.Use(mw.RateLimit(cfg.RateLimitPerMinute, time.Minute))
		r.Use(func(next http.Handler) http.Handler {
			return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.Header().Set("X-Content-Type-Options", "nosniff")
				w.Header().Set("X-Frame-Options", "DENY")
				w.Header().Set("X-XSS-Protection", "0")
				w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")
				w.Header().Set("Content-Security-Policy", "default-src 'self'")
				if !cfg.IsDevelopment {
					w.Header().Set("Strict-Transport-Security", "max-age=63072000; includeSubDomains")
				}
				next.ServeHTTP(w, r)
			})
		})
		r.Use(mw.CSRFProtection)
			r.Use(cors.Handler(cors.Options{
				AllowedOrigins:   []string{cfg.AllowedOrigin},
				AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
				AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
				AllowCredentials: true,
				MaxAge:           300,
			}))

		r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte("ok"))
		})

		r.Get("/ready", func(w http.ResponseWriter, r *http.Request) {
			if pingErr := sqlDB.PingContext(r.Context()); pingErr != nil {
				w.WriteHeader(http.StatusServiceUnavailable)
				_, _ = w.Write([]byte("database unreachable"))
				return
			}
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte("ok"))
		})

		if cfg.MetricsEnabled {
			r.Get("/metrics", func(w http.ResponseWriter, r *http.Request) {
				stats := sqlDB.Stats()
				w.Header().Set("Content-Type", "application/json")
				_, _ = fmt.Fprintf(w, `{
					"db_open_connections": %d,
					"db_in_use": %d,
					"db_idle": %d,
					"db_wait_count": %d,
					"db_wait_duration_ms": %d,
					"db_max_open_connections": %d
				}`,
					stats.OpenConnections,
					stats.InUse,
					stats.Idle,
					stats.WaitCount,
					stats.WaitDuration.Milliseconds(),
					stats.MaxOpenConnections,
				)
			})
		}

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
		r.Use(mw.RateLimit(cfg.AuthRateLimitPerMinute, time.Minute))
		r.Post("/firebase-login", authCtrl.LoginWithFirebase)
		r.Post("/register", authCtrl.Register)
		r.Post("/logout", authCtrl.Logout)
	})

		// Notification infrastructure
		fcmSvc, err := services.NewFCMService(cfg, logger)
		if err != nil {
			logger.Warn().Err(err).Msg("FCM service init failed — push notifications disabled")
		}
		notifSvc := services.NewNotificationService(dbQueries, fcmSvc, logger)
		triggers := services.NewNotificationTriggers(notifSvc)

		notifCtrl := ctrl.NewNotificationController(notifSvc, logger, cfg)

		// Create services with triggers wired
		staffSvc := services.NewStaffService(querier)
		staffSvc.SetTriggers(triggers)
		attSvc := services.NewAttendanceService(querier)
		attSvc.SetTriggers(triggers)
		ledgerSvc := services.NewLedgerService(querier)
		ledgerSvc.SetTriggers(triggers)
		disputeSvc := services.NewDisputeService(querier)
		disputeSvc.SetTriggers(triggers)
		payrollSvc := services.NewPayrollService(querier)
		payrollSvc.SetTriggers(triggers)
		advReqSvc := services.NewAdvanceRequestService(querier)
		advReqSvc.SetTriggers(triggers)

			shiftCtrl := ctrl.NewShiftController(services.NewShiftService(querier), logger, cfg)
			uploadCtrl := ctrl.NewUploadController(staffSvc, logger, cfg)
			staffCtrl := ctrl.NewStaffController(staffSvc, logger, cfg)
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
				r.Get("/{id}/overview", staffCtrl.Overview)
				r.Put("/{id}/manager", staffCtrl.AssignManager)
				r.Put("/{id}/default-shift", shiftCtrl.AssignDefaultShift)
			})

		meCtrl := ctrl.NewMeController(
			staffSvc,
			attSvc,
			ledgerSvc,
			payrollSvc,
			advReqSvc,
			logger, cfg,
		)
	r.Route("/api/v1/me", func(r chi.Router) {
		r.Use(mw.AuthMiddleware(cfg))
			r.Use(mw.TenantMiddleware())
			r.Get("/", meCtrl.Profile)
			r.Get("/overview", meCtrl.Overview)
			r.Get("/attendance", meCtrl.Attendance)
			r.Get("/ledger", meCtrl.Ledger)
			r.Get("/payslip", meCtrl.Payslip)
			r.Post("/advance-request", meCtrl.RequestAdvance)
			r.Post("/fcm-token", notifCtrl.RegisterToken)
			r.Delete("/fcm-token", notifCtrl.RemoveToken)
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

			attCtrl := ctrl.NewAttendanceController(attSvc, logger, cfg)
		r.Route("/api/v1/attendance", func(r chi.Router) {
			r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Get("/", attCtrl.ListByDate)
				r.Get("/roster", attCtrl.Roster)
				r.Get("/{id}", attCtrl.ListByEmployee)
				r.Post("/", attCtrl.Create)
				r.Put("/{id}", attCtrl.Update)
				r.Post("/bulk", attCtrl.BulkUpsert)
				r.Post("/lock", attCtrl.LockMonth)
			})

			ledgerCtrl := ctrl.NewLedgerController(ledgerSvc, logger, cfg)
		r.Route("/api/v1/ledger", func(r chi.Router) {
			r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Post("/", ledgerCtrl.CreateEntry)
				r.Get("/", ledgerCtrl.ListByTenant)
				r.Get("/total-outstanding", ledgerCtrl.GetTotalOutstanding)
				r.Get("/summary", ledgerCtrl.Summary)
				r.Get("/balance-summary", ledgerCtrl.BalanceSummary)
				r.Get("/{id}", ledgerCtrl.ListByEmployee)
				r.Get("/{id}/entry", ledgerCtrl.GetEntry)
				r.Put("/{id}/entry", ledgerCtrl.UpdateEntry)
				r.Delete("/{id}/entry", ledgerCtrl.DeleteEntry)
				r.Get("/{id}/balance", ledgerCtrl.GetBalance)
				r.Post("/{id}/settle", ledgerCtrl.SettleAccount)
			})

			disputeCtrl := ctrl.NewDisputeController(disputeSvc, logger, cfg)
		r.Route("/api/v1/disputes", func(r chi.Router) {
			r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Post("/", disputeCtrl.Create)
				r.Get("/", disputeCtrl.List)
				r.Post("/resolve", disputeCtrl.Resolve)
				r.Post("/reject", disputeCtrl.Reject)
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

			dashCtrl := ctrl.NewDashboardController(services.NewDashboardService(querier), services.NewReportService(querier), logger, cfg)
			r.Route("/api/v1/dashboard", func(r chi.Router) {
				r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Get("/", dashCtrl.Get)
			})

			advReqCtrl := ctrl.NewAdvanceRequestController(advReqSvc, logger, cfg)
		r.Route("/api/v1/advance-requests", func(r chi.Router) {
			r.Use(mw.AuthMiddleware(cfg))
				r.Use(mw.TenantMiddleware())
				r.Post("/", advReqCtrl.Create)
				r.Get("/", advReqCtrl.List)
				r.Put("/{id}/approve", advReqCtrl.Approve)
				r.Put("/{id}/deny", advReqCtrl.Deny)
			})

			r.With(mw.AuthMiddleware(cfg), mw.TenantMiddleware()).Get("/uploads/{file}", uploadCtrl.ServeFile)

			payrollCtrl := ctrl.NewPayrollController(payrollSvc, logger, cfg)
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

			onboardingCtrl := ctrl.NewOnboardingController(services.NewOnboardingService(querier), logger, cfg)
		r.Route("/api/v1/onboarding", func(r chi.Router) {
			r.Use(mw.AuthMiddleware(cfg))
			r.Use(mw.TenantMiddleware())
			r.Post("/setup", onboardingCtrl.Setup)
		})

		r.Route("/api/v1/notifications", func(r chi.Router) {
			r.Use(mw.AuthMiddleware(cfg))
			r.Use(mw.TenantMiddleware())
			r.Get("/", notifCtrl.List)
			r.Get("/unread-count", notifCtrl.UnreadCount)
			r.Put("/{id}/read", notifCtrl.MarkRead)
			r.Put("/read-all", notifCtrl.MarkAllRead)
		})

		srv := &http.Server{
			Addr:              cfg.Port,
			Handler:           r,
			ReadTimeout:       time.Duration(cfg.ReadTimeoutSeconds) * time.Second,
			ReadHeaderTimeout: time.Duration(cfg.ReadHeaderTimeoutSeconds) * time.Second,
			WriteTimeout:      time.Duration(cfg.WriteTimeoutSeconds) * time.Second,
			IdleTimeout:       time.Duration(cfg.IdleTimeoutSeconds) * time.Second,
		}

			var pprofSrv *http.Server
			if cfg.PprofAddr != "" {
				mux := http.NewServeMux()
				pprofHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
					if cfg.PprofPassword != "" {
						user, pass, ok := r.BasicAuth()
						if !ok || subtle.ConstantTimeCompare([]byte(pass), []byte(cfg.PprofPassword)) != 1 {
							w.Header().Set("WWW-Authenticate", `Basic realm="pprof"`)
							http.Error(w, "Unauthorized", http.StatusUnauthorized)
							return
						}
						_ = user
					}
					switch r.URL.Path {
					case "/debug/pprof/":
						pprof.Index(w, r)
					case "/debug/pprof/cmdline":
						pprof.Cmdline(w, r)
					case "/debug/pprof/profile":
						pprof.Profile(w, r)
					case "/debug/pprof/symbol":
						pprof.Symbol(w, r)
					case "/debug/pprof/trace":
						pprof.Trace(w, r)
					default:
						pprof.Index(w, r)
					}
				})
				mux.Handle("/debug/pprof/", pprofHandler)
				pprofSrv = &http.Server{
					Addr:              cfg.PprofAddr,
					Handler:           mux,
					ReadHeaderTimeout: 5 * time.Second,
				}
				go func() {
					logger.Info().Str("addr", pprofSrv.Addr).Msg("pprof listening")
					if err := pprofSrv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
						logger.Error().Err(err).Msg("pprof server failed")
					}
				}()
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

			if pprofSrv != nil {
				if err := pprofSrv.Shutdown(ctx); err != nil {
					logger.Error().Err(err).Msg("pprof shutdown failed")
				}
			}

			if err := sqlDB.Close(); err != nil {
				logger.Error().Err(err).Msg("database close failed")
			}

			logger.Info().Msg("Server stopped")
			return nil
		},
	}

	return apiCommand
}
