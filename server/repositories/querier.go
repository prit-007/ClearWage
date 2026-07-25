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
	TenantID        string  `json:"tenant_id"`
	Name            string  `json:"name"`
	Phone           string  `json:"phone"`
	WageType        string  `json:"wage_type"`
	WageAmount      float64 `json:"wage_amount"`
	DailyTargetUnits *int32 `json:"daily_target_units"`
	Role            string  `json:"role"`
}

type CreateHolidayParams struct {
	TenantID string `json:"tenant_id"`
	Name     string `json:"name"`
	Date     string `json:"date"`
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

type ListAttendanceByDateParams struct {
	TenantID string `json:"tenant_id"`
	Date     string `json:"date"`
}

type ListAttendanceByEmployeeMonthParams struct {
	EmployeeID string `json:"employee_id"`
	TenantID   string `json:"tenant_id"`
	StartDate  string `json:"start_date"`
	EndDate    string `json:"end_date"`
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
}

type ListLedgerByTenantParams struct {
	TenantID  string `json:"tenant_id"`
	StartDate string `json:"start_date"`
	EndDate   string `json:"end_date"`
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

type Querier interface {
	BulkUpsertAttendance(ctx context.Context, arg BulkUpsertAttendanceParams) ([]Attendance, error)
	CreateActivityLog(ctx context.Context, arg CreateActivityLogParams) (ActivityLog, error)
	CreateAdvanceRequest(ctx context.Context, arg CreateAdvanceRequestParams) (AdvanceRequest, error)
	CreateAttendance(ctx context.Context, arg CreateAttendanceParams) (Attendance, error)
	CreateEmployee(ctx context.Context, arg CreateEmployeeParams) (Employee, error)
	CreateHoliday(ctx context.Context, arg CreateHolidayParams) (Holiday, error)
	CreateLedgerEntry(ctx context.Context, arg CreateLedgerEntryParams) (Ledger, error)
	CreateShift(ctx context.Context, arg CreateShiftParams) (Shift, error)
	CreateSyncEvent(ctx context.Context, arg CreateSyncEventParams) (SyncQueue, error)
	CreateTenant(ctx context.Context, arg CreateTenantParams) (Tenant, error)
	DeleteHoliday(ctx context.Context, arg DeleteHolidayParams) error
	DeleteShift(ctx context.Context, arg DeleteShiftParams) error
	FindEmployeeByID(ctx context.Context, arg FindEmployeeByIDParams) (Employee, error)
	FindEmployeeByPhone(ctx context.Context, arg FindEmployeeByPhoneParams) (Employee, error)
	FindEmployeeByPhoneOnly(ctx context.Context, phone string) (Employee, error)
	FindShiftByID(ctx context.Context, arg FindShiftByIDParams) (Shift, error)
	FindSyncEventByEventID(ctx context.Context, arg FindSyncEventByEventIDParams) (SyncQueue, error)
	FindTenantByID(ctx context.Context, id string) (Tenant, error)
	FindTenantByPhone(ctx context.Context, phone string) (Tenant, error)
	GetBalanceByEmployee(ctx context.Context, arg GetBalanceByEmployeeParams) (int32, error)
	GetDailyJamaTotal(ctx context.Context, tenantID string, date string) (float64, error)
	GetLeavePolicyByTenant(ctx context.Context, tenantID string) (LeavePolicy, error)
	GetStaffProfile(ctx context.Context, arg GetStaffProfileParams) (StaffProfile, error)
	GetTenantConfig(ctx context.Context, tenantID string) (TenantConfig, error)
	GetTotalOutstanding(ctx context.Context, tenantID string) (float64, error)
	ListActivityLogsByTenant(ctx context.Context, tenantID string, limit int32) ([]ActivityLog, error)
	ListAttendanceByDate(ctx context.Context, arg ListAttendanceByDateParams) ([]Attendance, error)
	ListAttendanceByDateRange(ctx context.Context, tenantID string, startDate string, endDate string) ([]Attendance, error)
	ListAttendanceByEmployeeMonth(ctx context.Context, arg ListAttendanceByEmployeeMonthParams) ([]Attendance, error)
	ListAdvanceRequestsByTenant(ctx context.Context, tenantID string, status string) ([]AdvanceRequest, error)
	ListEmployeesByTenant(ctx context.Context, arg ListEmployeesByTenantParams) ([]Employee, error)
	ListHolidaysByTenant(ctx context.Context, tenantID string) ([]Holiday, error)
	ListLedgerByEmployeeMonth(ctx context.Context, arg ListLedgerByEmployeeMonthParams) ([]Ledger, error)
	ListLedgerByTenant(ctx context.Context, arg ListLedgerByTenantParams) ([]Ledger, error)
	ListPendingSyncEvents(ctx context.Context, tenantID string) ([]SyncQueue, error)
	ListShiftsByTenant(ctx context.Context, tenantID string) ([]Shift, error)
	LockAttendanceMonth(ctx context.Context, arg LockAttendanceMonthParams) error
	SoftDeleteEmployee(ctx context.Context, arg SoftDeleteEmployeeParams) error
	UpdateAdvanceRequestStatus(ctx context.Context, arg UpdateAdvanceRequestStatusParams) (AdvanceRequest, error)
	UpdateAttendance(ctx context.Context, arg UpdateAttendanceParams) (Attendance, error)
	UpdateEmployee(ctx context.Context, arg UpdateEmployeeParams) (Employee, error)
	UpdateEmployeeDefaultShift(ctx context.Context, arg UpdateEmployeeDefaultShiftParams) (Employee, error)
	UpdateEmployeeManager(ctx context.Context, arg UpdateEmployeeManagerParams) (Employee, error)
	UpdateEmployeePhotoURL(ctx context.Context, arg UpdateEmployeePhotoURLParams) (Employee, error)
	UpdateShift(ctx context.Context, arg UpdateShiftParams) (Shift, error)
	UpdateSyncEventStatus(ctx context.Context, arg UpdateSyncEventStatusParams) (SyncQueue, error)
	UpsertLeavePolicy(ctx context.Context, arg UpsertLeavePolicyParams) (LeavePolicy, error)
	UpsertTenantConfig(ctx context.Context, arg UpsertTenantConfigParams) (TenantConfig, error)
}
