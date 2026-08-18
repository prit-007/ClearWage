package repositories

import (
	"context"
	"time"
)

type CreateAdvanceRequestParams struct {
	TenantID   string  `json:"tenant_id"`
	EmployeeID string  `json:"employee_id"`
	Amount     float64 `json:"amount"`
	Note       *string `json:"note"`
	Status     string  `json:"status"`
}

type CreateActivityLogParams struct {
	TenantID   string  `json:"tenant_id"`
	EmployeeID *string `json:"employee_id"`
	Action     string  `json:"action"`
	EntityType string  `json:"entity_type"`
	EntityID   *string `json:"entity_id"`
	Details    *[]byte `json:"details"`
	CreatedBy  string  `json:"created_by"`
}

type BulkUpsertAttendanceParams struct {
	TenantID               string  `json:"tenant_id"`
	EmployeeID             string  `json:"employee_id"`
	Date                   string  `json:"date"`
	ShiftID                *string `json:"shift_id"`
	Status                 string  `json:"status"`
	OvertimeHours          float64 `json:"overtime_hours"`
	OvertimeRateMultiplier float64 `json:"overtime_rate_multiplier"`
	UnitsProduced          *int32  `json:"units_produced"`
}

type CreateAttendanceParams struct {
	TenantID               string     `json:"tenant_id"`
	EmployeeID             string     `json:"employee_id"`
	Date                   string     `json:"date"`
	ShiftID                *string    `json:"shift_id"`
	Status                 string     `json:"status"`
	CheckInTime            *time.Time `json:"check_in_time"`
	CheckOutTime           *time.Time `json:"check_out_time"`
	OvertimeHours          float64    `json:"overtime_hours"`
	OvertimeRateMultiplier float64    `json:"overtime_rate_multiplier"`
	UnitsProduced          *int32     `json:"units_produced"`
}

type CreateEmployeeParams struct {
	TenantID              string  `json:"tenant_id"`
	Name                  string  `json:"name"`
	Phone                 string  `json:"phone"`
	Designation           *string `json:"designation"`
	WageType              string  `json:"wage_type"`
	WageAmount            float64 `json:"wage_amount"`
	DailyTargetUnits      *int32  `json:"daily_target_units"`
	DateOfJoining         *string `json:"date_of_joining"`
	PanNumber             *string `json:"pan_number"`
	AadhaarNumber         *string `json:"aadhaar_number"`
	PfNumber              *string `json:"pf_number"`
	BankAccountNumber     *string `json:"bank_account_number"`
	BankIfsc              *string `json:"bank_ifsc"`
	UpiID                 *string `json:"upi_id"`
	EmergencyContactName  *string `json:"emergency_contact_name"`
	EmergencyContactPhone *string `json:"emergency_contact_phone"`
	HealthNotes           *string `json:"health_notes"`
	CurrentAddress        *string `json:"current_address"`
	PermanentAddress      *string `json:"permanent_address"`
	Role                  string  `json:"role"`
}

type CreateEmployeeDocumentParams struct {
	TenantID     string  `json:"tenant_id"`
	EmployeeID   string  `json:"employee_id"`
	DocType      string  `json:"doc_type"`
	FilePath     string  `json:"file_path"`
	PublicID     *string `json:"public_id"`
	OriginalName *string `json:"original_name"`
}

type DeleteEmployeeDocumentParams struct {
	TenantID   string `json:"tenant_id"`
	EmployeeID string `json:"employee_id"`
	DocType    string `json:"doc_type"`
}

type CreateHolidayParams struct {
	TenantID    string `json:"tenant_id"`
	Name        string `json:"name"`
	Date        string `json:"date"`
	IsRecurring bool   `json:"is_recurring"`
}

type CreateLedgerEntryParams struct {
	TenantID           string  `json:"tenant_id"`
	EmployeeID         string  `json:"employee_id"`
	Date               string  `json:"date"`
	Type               string  `json:"type"`
	Amount             float64 `json:"amount"`
	Note               *string `json:"note"`
	LinkedPayrollMonth *string `json:"linked_payroll_month"`
	CreatedBy          string  `json:"created_by"`
}

type CreateShiftParams struct {
	TenantID           string `json:"tenant_id"`
	Name               string `json:"name"`
	StartTime          string `json:"start_time"`
	EndTime            string `json:"end_time"`
	CrossesMidnight    bool   `json:"crosses_midnight"`
	GracePeriodMinutes int32  `json:"grace_period_minutes"`
	IsDefault          bool   `json:"is_default"`
}

type CreateSyncEventParams struct {
	TenantID  string `json:"tenant_id"`
	EventID   string `json:"event_id"`
	EventType string `json:"event_type"`
	Payload   []byte `json:"payload"`
	Status    string `json:"status"`
}

type CreateTenantParams struct {
	Name  string `json:"name"`
	Phone string `json:"phone"`
}

type DeleteHolidayParams struct {
	ID       string `json:"id"`
	TenantID string `json:"tenant_id"`
}

type DeleteShiftParams struct {
	ID       string `json:"id"`
	TenantID string `json:"tenant_id"`
}

type FindEmployeeByIDParams struct {
	ID       string `json:"id"`
	TenantID string `json:"tenant_id"`
}

type FindEmployeeByPhoneParams struct {
	Phone    string `json:"phone"`
	TenantID string `json:"tenant_id"`
}

type FindShiftByIDParams struct {
	ID       string `json:"id"`
	TenantID string `json:"tenant_id"`
}

type FindSyncEventByEventIDParams struct {
	TenantID string `json:"tenant_id"`
	EventID  string `json:"event_id"`
}

type GetBalanceByEmployeeParams struct {
	EmployeeID string `json:"employee_id"`
	TenantID   string `json:"tenant_id"`
}

type GetEmployeeAttendanceSummaryParams struct {
	TenantID   string `json:"tenant_id"`
	EmployeeID string `json:"employee_id"`
	StartDate  string `json:"start_date"`
	EndDate    string `json:"end_date"`
}

type GetEmployeeLedgerSummaryParams struct {
	TenantID   string `json:"tenant_id"`
	EmployeeID string `json:"employee_id"`
	StartDate  string `json:"start_date"`
	EndDate    string `json:"end_date"`
}

type UpdateTenantProfileParams struct {
	ID      string  `json:"id"`
	Name    string  `json:"name"`
	Phone   string  `json:"phone"`
	Address *string `json:"address"`
}

type ListAttendanceByDateParams struct {
	TenantID string `json:"tenant_id"`
	Date     string `json:"date"`
	Limit    int32  `json:"limit"`
	Offset   int32  `json:"offset"`
}

type ListAttendanceByDateRangeParams struct {
	TenantID  string `json:"tenant_id"`
	StartDate string `json:"start_date"`
	EndDate   string `json:"end_date"`
	Limit     int32  `json:"limit"`
	Offset    int32  `json:"offset"`
}

type ListAttendanceByEmployeeMonthParams struct {
	EmployeeID string `json:"employee_id"`
	TenantID   string `json:"tenant_id"`
	StartDate  string `json:"start_date"`
	EndDate    string `json:"end_date"`
	Limit      int32  `json:"limit"`
	Offset     int32  `json:"offset"`
}

type ListEmployeesByTenantParams struct {
	TenantID string  `json:"tenant_id"`
	Limit    int32   `json:"limit"`
	Offset   int32   `json:"offset"`
	Query    *string `json:"query"`
	Status   *string `json:"status"`
}

type ListLedgerByEmployeeMonthParams struct {
	EmployeeID string `json:"employee_id"`
	TenantID   string `json:"tenant_id"`
	StartDate  string `json:"start_date"`
	EndDate    string `json:"end_date"`
	Limit      int32  `json:"limit"`
	Offset     int32  `json:"offset"`
}

type ListLedgerByTenantParams struct {
	TenantID  string `json:"tenant_id"`
	StartDate string `json:"start_date"`
	EndDate   string `json:"end_date"`
	Limit     int32  `json:"limit"`
	Offset    int32  `json:"offset"`
}

type ListActivityLogsByTenantParams struct {
	TenantID string `json:"tenant_id"`
	Limit    int32  `json:"limit"`
	Offset   int32  `json:"offset"`
}

type ListAdvanceRequestsByTenantParams struct {
	TenantID string `json:"tenant_id"`
	Status   string `json:"status"`
	Limit    int32  `json:"limit"`
	Offset   int32  `json:"offset"`
}

type ListShiftsByTenantParams struct {
	TenantID string `json:"tenant_id"`
	Limit    int32  `json:"limit"`
	Offset   int32  `json:"offset"`
}

type ListHolidaysByTenantParams struct {
	TenantID string `json:"tenant_id"`
	Limit    int32  `json:"limit"`
	Offset   int32  `json:"offset"`
}

type ListPendingSyncEventsParams struct {
	TenantID string `json:"tenant_id"`
	Limit    int32  `json:"limit"`
	Offset   int32  `json:"offset"`
}

type GetStaffProfileParams struct {
	ID       string `json:"id"`
	TenantID string `json:"tenant_id"`
}

type LockAttendanceMonthParams struct {
	TenantID  string `json:"tenant_id"`
	StartDate string `json:"start_date"`
	EndDate   string `json:"end_date"`
}

type SoftDeleteEmployeeParams struct {
	ID       string `json:"id"`
	TenantID string `json:"tenant_id"`
}

type UpdateAttendanceParams struct {
	ID                     string     `json:"id"`
	TenantID               string     `json:"tenant_id"`
	ShiftID                *string    `json:"shift_id"`
	Status                 string     `json:"status"`
	CheckInTime            *time.Time `json:"check_in_time"`
	CheckOutTime           *time.Time `json:"check_out_time"`
	OvertimeHours          float64    `json:"overtime_hours"`
	OvertimeRateMultiplier float64    `json:"overtime_rate_multiplier"`
	UnitsProduced          *int32     `json:"units_produced"`
	EditedBy               *string    `json:"edited_by"`
	ComputedWage           *float64   `json:"computed_wage"`
	ExpectedVersion        int32      `json:"expected_version"`
}

type FindEmployeeByPhoneOnlyParams struct {
	Phone string `json:"phone"`
}

type GetEmployeeDocumentByTypeParams struct {
	TenantID   string `json:"tenant_id"`
	EmployeeID string `json:"employee_id"`
	DocType    string `json:"doc_type"`
}

type ListEmployeeDocumentsByEmployeeParams struct {
	TenantID   string `json:"tenant_id"`
	EmployeeID string `json:"employee_id"`
}

type UpdateEmployeeParams struct {
	ID                    string   `json:"id"`
	Name                  string   `json:"name"`
	Phone                 string   `json:"phone"`
	Designation           *string  `json:"designation"`
	WageType              string   `json:"wage_type"`
	WageAmount            float64  `json:"wage_amount"`
	DefaultShiftID        *string  `json:"default_shift_id"`
	PieceRateItemName     *string  `json:"piece_rate_item_name"`
	PieceRatePerUnit      *float64 `json:"piece_rate_per_unit"`
	DailyTargetUnits      *int32   `json:"daily_target_units"`
	DateOfJoining         *string  `json:"date_of_joining"`
	PanNumber             *string  `json:"pan_number"`
	AadhaarNumber         *string  `json:"aadhaar_number"`
	PfNumber              *string  `json:"pf_number"`
	PhotoUrl              *string  `json:"photo_url"`
	BankAccountNumber     *string  `json:"bank_account_number"`
	BankIfsc              *string  `json:"bank_ifsc"`
	UpiID                 *string  `json:"upi_id"`
	EmergencyContactName  *string  `json:"emergency_contact_name"`
	EmergencyContactPhone *string  `json:"emergency_contact_phone"`
	HealthNotes           *string  `json:"health_notes"`
	CurrentAddress        *string  `json:"current_address"`
	PermanentAddress      *string  `json:"permanent_address"`
	Role                  string   `json:"role"`
	IsActive              bool     `json:"is_active"`
	TenantID              string   `json:"tenant_id"`
	ExpectedVersion       int32    `json:"expected_version"`
}

type UpdateEmployeeDefaultShiftParams struct {
	DefaultShiftID string `json:"default_shift_id"`
	ID             string `json:"id"`
	TenantID       string `json:"tenant_id"`
}

type UpdateEmployeeManagerParams struct {
	ID        string  `json:"id"`
	TenantID  string  `json:"tenant_id"`
	ManagerID *string `json:"manager_id"`
}

type UpdateEmployeePhotoURLParams struct {
	ID       string `json:"id"`
	TenantID string `json:"tenant_id"`
	PhotoURL string `json:"photo_url"`
}

type UpdateShiftParams struct {
	ID                 string `json:"id"`
	Name               string `json:"name"`
	StartTime          string `json:"start_time"`
	EndTime            string `json:"end_time"`
	CrossesMidnight    bool   `json:"crosses_midnight"`
	GracePeriodMinutes int32  `json:"grace_period_minutes"`
	IsDefault          bool   `json:"is_default"`
	TenantID           string `json:"tenant_id"`
}

type UpsertTenantConfigParams struct {
	TenantID            string  `json:"tenant_id"`
	OTTrigger           string  `json:"ot_trigger"`
	OTThresholdHours    float64 `json:"ot_threshold_hours"`
	OTMultiplierDefault float64 `json:"ot_multiplier_default"`
	OTRounding          int32   `json:"ot_rounding"`
	WageBasis           string  `json:"wage_basis"`
	WeekOffPaid         bool    `json:"week_off_paid"`
	WeeklyOffs          string  `json:"weekly_offs"`
}

type UpdateSyncEventStatusParams struct {
	ID           string  `json:"id"`
	TenantID     string  `json:"tenant_id"`
	Status       string  `json:"status"`
	ErrorMessage *string `json:"error_message"`
}

type UpsertLeavePolicyParams struct {
	TenantID               string `json:"tenant_id"`
	PaidLeaveDaysPerYear   int32  `json:"paid_leave_days_per_year"`
	UnpaidLeaveDaysPerYear int32  `json:"unpaid_leave_days_per_year"`
}

type UpdateAdvanceRequestStatusParams struct {
	ID         string  `json:"id"`
	TenantID   string  `json:"tenant_id"`
	Status     string  `json:"status"`
	ApprovedBy *string `json:"approved_by"`
	DeniedBy   *string `json:"denied_by"`
}

type LedgerDispute struct {
	ID             string  `json:"id"`
	TenantID       string  `json:"tenant_id"`
	LedgerID       string  `json:"ledger_id"`
	EmployeeID     string  `json:"employee_id"`
	RaisedBy       string  `json:"raised_by"`
	Reason         string  `json:"reason"`
	Status         string  `json:"status"`
	ResolvedBy     *string `json:"resolved_by"`
	ResolutionNote *string `json:"resolution_note"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

type CreateDisputeParams struct {
	TenantID   string `json:"tenant_id"`
	LedgerID   string `json:"ledger_id"`
	EmployeeID string `json:"employee_id"`
	RaisedBy   string `json:"raised_by"`
	Reason     string `json:"reason"`
}

type ListDisputesByTenantParams struct {
	TenantID string `json:"tenant_id"`
	Status   string `json:"status"`
	Limit    int32  `json:"limit"`
	Offset   int32  `json:"offset"`
}

type ListDisputesByTenantRow struct {
	ID             string    `json:"id"`
	TenantID       string    `json:"tenant_id"`
	LedgerID       string    `json:"ledger_id"`
	EmployeeID     string    `json:"employee_id"`
	RaisedBy       string    `json:"raised_by"`
	Reason         string    `json:"reason"`
	Status         string    `json:"status"`
	ResolvedBy     *string   `json:"resolved_by"`
	ResolutionNote *string   `json:"resolution_note"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
	RaisedByName   string    `json:"raised_by_name"`
}

type ResolveDisputeParams struct {
	ID             string  `json:"id"`
	ResolvedBy     string  `json:"resolved_by"`
	ResolutionNote *string `json:"resolution_note"`
	TenantID       string  `json:"tenant_id"`
}

type RejectDisputeParams struct {
	ID             string  `json:"id"`
	ResolvedBy     string  `json:"resolved_by"`
	ResolutionNote *string `json:"resolution_note"`
	TenantID       string  `json:"tenant_id"`
}

type Querier interface {
	BulkUpsertAttendance(ctx context.Context, arg BulkUpsertAttendanceParams) ([]Attendance, error)
	CreateActivityLog(ctx context.Context, arg CreateActivityLogParams) (ActivityLog, error)
	CreateAdvanceRequest(ctx context.Context, arg CreateAdvanceRequestParams) (AdvanceRequest, error)
	CreateAttendance(ctx context.Context, arg CreateAttendanceParams) (Attendance, error)
	CreateDispute(ctx context.Context, arg CreateDisputeParams) (LedgerDispute, error)
	CreateEmployee(ctx context.Context, arg CreateEmployeeParams) (Employee, error)
	CreateEmployeeDocument(ctx context.Context, arg CreateEmployeeDocumentParams) (EmployeeDocument, error)
	CreateHoliday(ctx context.Context, arg CreateHolidayParams) (Holiday, error)
	CreateLedgerEntry(ctx context.Context, arg CreateLedgerEntryParams) (Ledger, error)
	CreateShift(ctx context.Context, arg CreateShiftParams) (Shift, error)
	CreateSyncEvent(ctx context.Context, arg CreateSyncEventParams) (SyncQueue, error)
	CreateTenant(ctx context.Context, arg CreateTenantParams) (Tenant, error)
	DeleteHoliday(ctx context.Context, arg DeleteHolidayParams) error
	DeleteEmployeeDocument(ctx context.Context, arg DeleteEmployeeDocumentParams) error
	DeleteTenant(ctx context.Context, tenantID string) error
	DeleteShift(ctx context.Context, arg DeleteShiftParams) error
	FindEmployeeByID(ctx context.Context, arg FindEmployeeByIDParams) (Employee, error)
	FindEmployeeByPhone(ctx context.Context, arg FindEmployeeByPhoneParams) (Employee, error)
	FindEmployeeByPhoneOnly(ctx context.Context, phone string) (Employee, error)
	FindShiftByID(ctx context.Context, arg FindShiftByIDParams) (Shift, error)
	FindSyncEventByEventID(ctx context.Context, arg FindSyncEventByEventIDParams) (SyncQueue, error)
	FindTenantByID(ctx context.Context, id string) (Tenant, error)
	FindTenantByPhone(ctx context.Context, phone string) (Tenant, error)
	GetBalanceByEmployee(ctx context.Context, arg GetBalanceByEmployeeParams) (float64, error)
	GetDailyJamaTotal(ctx context.Context, tenantID string, date string) (float64, error)
	GetEmployeeAttendanceSummary(ctx context.Context, arg GetEmployeeAttendanceSummaryParams) (EmployeeAttendanceSummary, error)
	GetEmployeeDocumentByType(ctx context.Context, arg GetEmployeeDocumentByTypeParams) (EmployeeDocument, error)
	GetEmployeeLedgerSummary(ctx context.Context, arg GetEmployeeLedgerSummaryParams) (LedgerSummaryRange, error)
	GetLeavePolicyByTenant(ctx context.Context, tenantID string) (LeavePolicy, error)
	GetLedgerSummaryRange(ctx context.Context, tenantID string, startDate string, endDate string) (LedgerSummaryRange, error)
	GetStaffProfile(ctx context.Context, arg GetStaffProfileParams) (StaffProfile, error)
	GetTenantConfig(ctx context.Context, tenantID string) (TenantConfig, error)
	GetTotalOutstanding(ctx context.Context, tenantID string) (float64, error)
	GetDashboardSnapshot(ctx context.Context, tenantID, today, monthStart string) (DashboardSnapshot, error)
	GetEmployeeBalanceSummary(ctx context.Context, tenantID string) ([]EmployeeBalanceSummary, error)
	ListEmployeeBalances(ctx context.Context, tenantID string) ([]EmployeeBalance, error)
	GetDailySummary(ctx context.Context, tenantID, date string) (DailySummary, error)
	GetWageBillTrends(ctx context.Context, tenantID, startDate, endDate string) ([]WageBillTrend, error)
	ListActivityLogsByTenant(ctx context.Context, arg ListActivityLogsByTenantParams) ([]ActivityLog, error)
	ListAdvanceRequestsByTenant(ctx context.Context, arg ListAdvanceRequestsByTenantParams) ([]AdvanceRequest, error)
	ListAttendanceByDate(ctx context.Context, arg ListAttendanceByDateParams) ([]Attendance, error)
	ListAttendanceByDateRange(ctx context.Context, arg ListAttendanceByDateRangeParams) ([]Attendance, error)
	ListAttendanceByEmployeeMonth(ctx context.Context, arg ListAttendanceByEmployeeMonthParams) ([]Attendance, error)
	ListEmployeesByTenant(ctx context.Context, arg ListEmployeesByTenantParams) ([]Employee, error)
	ListEmployeeDocumentsByEmployee(ctx context.Context, arg ListEmployeeDocumentsByEmployeeParams) ([]EmployeeDocument, error)
	ListHolidaysByTenant(ctx context.Context, arg ListHolidaysByTenantParams) ([]Holiday, error)
	ListLedgerByEmployeeMonth(ctx context.Context, arg ListLedgerByEmployeeMonthParams) ([]Ledger, error)
	ListLedgerByTenant(ctx context.Context, arg ListLedgerByTenantParams) ([]Ledger, error)
	ListPendingSyncEvents(ctx context.Context, arg ListPendingSyncEventsParams) ([]SyncQueue, error)
	ListRosterByDate(ctx context.Context, tenantID string, date string) ([]RosterRow, error)
	ListEmployeesByTenantExplicit(ctx context.Context, tenantID string, limit, offset int32) ([]Employee, error)
	ListAttendanceByDateRangeExplicit(ctx context.Context, tenantID, startDate, endDate string, limit, offset int32) ([]Attendance, error)
	ListLedgerByTenantExplicit(ctx context.Context, tenantID, startDate, endDate string, limit, offset int32) ([]Ledger, error)
	ListAttendanceByEmployeeMonthExplicit(ctx context.Context, employeeID, tenantID, startDate, endDate string, limit, offset int32) ([]Attendance, error)
	ListLedgerByEmployeeMonthExplicit(ctx context.Context, employeeID, tenantID, startDate, endDate string, limit, offset int32) ([]Ledger, error)
	ListShiftsByTenant(ctx context.Context, arg ListShiftsByTenantParams) ([]Shift, error)
	ListDisputesByTenant(ctx context.Context, arg ListDisputesByTenantParams) ([]ListDisputesByTenantRow, error)
	LockAttendanceMonth(ctx context.Context, arg LockAttendanceMonthParams) error
	RejectDispute(ctx context.Context, arg RejectDisputeParams) (LedgerDispute, error)
	ResolveDispute(ctx context.Context, arg ResolveDisputeParams) (LedgerDispute, error)
	SoftDeleteEmployee(ctx context.Context, arg SoftDeleteEmployeeParams) error
	UpdateAdvanceRequestStatus(ctx context.Context, arg UpdateAdvanceRequestStatusParams) (AdvanceRequest, error)
	UpdateAttendance(ctx context.Context, arg UpdateAttendanceParams) (Attendance, error)
	UpdateEmployee(ctx context.Context, arg UpdateEmployeeParams) (Employee, error)
	UpdateEmployeeDefaultShift(ctx context.Context, arg UpdateEmployeeDefaultShiftParams) (Employee, error)
	UpdateEmployeeManager(ctx context.Context, arg UpdateEmployeeManagerParams) (Employee, error)
	UpdateEmployeePhotoURL(ctx context.Context, arg UpdateEmployeePhotoURLParams) (Employee, error)
	UpdateShift(ctx context.Context, arg UpdateShiftParams) (Shift, error)
	UpdateSyncEventStatus(ctx context.Context, arg UpdateSyncEventStatusParams) (SyncQueue, error)
	UpdateTenantProfile(ctx context.Context, arg UpdateTenantProfileParams) error
	UpsertLeavePolicy(ctx context.Context, arg UpsertLeavePolicyParams) (LeavePolicy, error)
	UpsertTenantConfig(ctx context.Context, arg UpsertTenantConfigParams) (TenantConfig, error)
}
