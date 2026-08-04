package repositories

import "time"

type ActivityLog struct {
	ID         string    `json:"id" db:"id"`
	TenantID   string    `json:"tenant_id" db:"tenant_id"`
	EmployeeID *string   `json:"employee_id" db:"employee_id"`
	Action     string    `json:"action" db:"action"`
	EntityType string    `json:"entity_type" db:"entity_type"`
	EntityID   *string   `json:"entity_id" db:"entity_id"`
	Details    *[]byte   `json:"details" db:"details"`
	CreatedBy  string    `json:"created_by" db:"created_by"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
}

type AdvanceRequest struct {
	ID            string    `json:"id" db:"id"`
	TenantID      string    `json:"tenant_id" db:"tenant_id"`
	EmployeeID    string    `json:"employee_id" db:"employee_id"`
	Amount        float64   `json:"amount" db:"amount"`
	Status        string    `json:"status" db:"status"`
	Note          *string   `json:"note" db:"note"`
	ApprovedBy    *string   `json:"approved_by" db:"approved_by"`
	DeniedBy      *string   `json:"denied_by" db:"denied_by"`
	EmployeeName  *string   `json:"employee_name" db:"employee_name"`
	EmployeePhoto *string   `json:"employee_photo" db:"employee_photo"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time `json:"updated_at" db:"updated_at"`
}

type Attendance struct {
	ID                     string     `json:"id" db:"id"`
	TenantID               string     `json:"tenant_id" db:"tenant_id"`
	EmployeeID             string     `json:"employee_id" db:"employee_id"`
	Date                   string     `json:"date" db:"date"`
	ShiftID                *string    `json:"shift_id" db:"shift_id"`
	Status                 string     `json:"status" db:"status"`
	CheckInTime            *time.Time `json:"check_in_time" db:"check_in_time"`
	CheckOutTime           *time.Time `json:"check_out_time" db:"check_out_time"`
	OvertimeHours          float64    `json:"overtime_hours" db:"overtime_hours"`
	OvertimeRateMultiplier float64    `json:"overtime_rate_multiplier" db:"overtime_rate_multiplier"`
	UnitsProduced          *int32     `json:"units_produced" db:"units_produced"`
	ComputedWage           *float64   `json:"computed_wage" db:"computed_wage"`
	IsLocked               bool       `json:"is_locked" db:"is_locked"`
	EditedBy               *string    `json:"edited_by" db:"edited_by"`
	EditedAt               *time.Time `json:"edited_at" db:"edited_at"`
	EmployeeName           *string    `json:"employee_name" db:"employee_name"`
	EmployeePhoto          *string    `json:"employee_photo" db:"employee_photo"`
	CreatedAt              time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt              time.Time  `json:"updated_at" db:"updated_at"`
}

type Employee struct {
	ID                    string    `json:"id" db:"id"`
	TenantID              string    `json:"tenant_id" db:"tenant_id"`
	Name                  string    `json:"name" db:"name"`
	Phone                 string    `json:"phone" db:"phone"`
	Designation           *string   `json:"designation" db:"designation"`
	WageType              string    `json:"wage_type" db:"wage_type"`
	WageAmount            float64   `json:"wage_amount" db:"wage_amount"`
	DefaultShiftID        *string   `json:"default_shift_id" db:"default_shift_id"`
	ManagerID             *string   `json:"manager_id" db:"manager_id"`
	PieceRateItemName     *string   `json:"piece_rate_item_name" db:"piece_rate_item_name"`
	PieceRatePerUnit      *float64  `json:"piece_rate_per_unit" db:"piece_rate_per_unit"`
	DailyTargetUnits      *int32    `json:"daily_target_units" db:"daily_target_units"`
	DateOfJoining         *string   `json:"date_of_joining" db:"date_of_joining"`
	PanNumber             *string   `json:"pan_number" db:"pan_number"`
	AadhaarNumber         *string   `json:"aadhaar_number" db:"aadhaar_number"`
	PfNumber              *string   `json:"pf_number" db:"pf_number"`
	PhotoUrl              *string   `json:"photo_url" db:"photo_url"`
	BankAccountNumber     *string   `json:"bank_account_number" db:"bank_account_number"`
	BankIfsc              *string   `json:"bank_ifsc" db:"bank_ifsc"`
	UpiID                 *string   `json:"upi_id" db:"upi_id"`
	EmergencyContactName  *string   `json:"emergency_contact_name" db:"emergency_contact_name"`
	EmergencyContactPhone *string   `json:"emergency_contact_phone" db:"emergency_contact_phone"`
	HealthNotes           *string   `json:"health_notes" db:"health_notes"`
	CurrentAddress        *string   `json:"current_address" db:"current_address"`
	PermanentAddress      *string   `json:"permanent_address" db:"permanent_address"`
	Role                  string    `json:"role" db:"role"`
	IsActive              bool      `json:"is_active" db:"is_active"`
	CreatedAt             time.Time `json:"created_at" db:"created_at"`
	UpdatedAt             time.Time `json:"updated_at" db:"updated_at"`
}

type EmployeeDocument struct {
	ID           string    `json:"id" db:"id"`
	TenantID     string    `json:"tenant_id" db:"tenant_id"`
	EmployeeID   string    `json:"employee_id" db:"employee_id"`
	DocType      string    `json:"doc_type" db:"doc_type"`
	FilePath     string    `json:"file_path" db:"file_path"`
	PublicID     *string   `json:"public_id" db:"public_id"`
	OriginalName *string   `json:"original_name" db:"original_name"`
	UploadedAt   time.Time `json:"uploaded_at" db:"uploaded_at"`
}

type Holiday struct {
	ID          string    `json:"id" db:"id"`
	TenantID    string    `json:"tenant_id" db:"tenant_id"`
	Name        string    `json:"name" db:"name"`
	Date        string    `json:"date" db:"date"`
	IsRecurring bool      `json:"is_recurring" db:"is_recurring"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

type LeavePolicy struct {
	ID                     string    `json:"id" db:"id"`
	TenantID               string    `json:"tenant_id" db:"tenant_id"`
	PaidLeaveDaysPerYear   int32     `json:"paid_leave_days_per_year" db:"paid_leave_days_per_year"`
	UnpaidLeaveDaysPerYear int32     `json:"unpaid_leave_days_per_year" db:"unpaid_leave_days_per_year"`
	CreatedAt              time.Time `json:"created_at" db:"created_at"`
	UpdatedAt              time.Time `json:"updated_at" db:"updated_at"`
}

type Ledger struct {
	ID                 string    `json:"id" db:"id"`
	TenantID           string    `json:"tenant_id" db:"tenant_id"`
	EmployeeID         string    `json:"employee_id" db:"employee_id"`
	Date               string    `json:"date" db:"date"`
	Type               string    `json:"type" db:"type"`
	Amount             float64   `json:"amount" db:"amount"`
	Note               *string   `json:"note" db:"note"`
	LinkedPayrollMonth *string   `json:"linked_payroll_month" db:"linked_payroll_month"`
	CreatedBy          string    `json:"created_by" db:"created_by"`
	EmployeeName       *string   `json:"employee_name" db:"employee_name"`
	EmployeePhoto      *string   `json:"employee_photo" db:"employee_photo"`
	CreatedAt          time.Time `json:"created_at" db:"created_at"`
	UpdatedAt          time.Time `json:"updated_at" db:"updated_at"`
}

type Shift struct {
	ID                 string    `json:"id" db:"id"`
	TenantID           string    `json:"tenant_id" db:"tenant_id"`
	Name               string    `json:"name" db:"name"`
	StartTime          string    `json:"start_time" db:"start_time"`
	EndTime            string    `json:"end_time" db:"end_time"`
	CrossesMidnight    bool      `json:"crosses_midnight" db:"crosses_midnight"`
	GracePeriodMinutes int32     `json:"grace_period_minutes" db:"grace_period_minutes"`
	IsDefault          bool      `json:"is_default" db:"is_default"`
	CreatedAt          time.Time `json:"created_at" db:"created_at"`
	UpdatedAt          time.Time `json:"updated_at" db:"updated_at"`
}

type SyncQueue struct {
	ID           string    `json:"id" db:"id"`
	TenantID     string    `json:"tenant_id" db:"tenant_id"`
	EventID      string    `json:"event_id" db:"event_id"`
	EventType    string    `json:"event_type" db:"event_type"`
	Payload      []byte    `json:"payload" db:"payload"`
	Status       string    `json:"status" db:"status"`
	ErrorMessage *string   `json:"error_message" db:"error_message"`
	RetryCount   int32     `json:"retry_count" db:"retry_count"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
}

type Tenant struct {
	ID        string    `json:"id" db:"id"`
	Name      string    `json:"name" db:"name"`
	Phone     string    `json:"phone" db:"phone"`
	Address   *string   `json:"address" db:"address"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

type RosterRow struct {
	EmployeeID        string     `json:"employee_id" db:"employee_id"`
	Name              string     `json:"name" db:"name"`
	Phone             string     `json:"phone" db:"phone"`
	PhotoURL          *string    `json:"photo_url" db:"photo_url"`
	Designation       *string    `json:"designation" db:"designation"`
	Role              string     `json:"role" db:"role"`
	IsActive          bool       `json:"is_active" db:"is_active"`
	DefaultShiftID    *string    `json:"default_shift_id" db:"default_shift_id"`
	AttendanceShiftID *string    `json:"attendance_shift_id" db:"attendance_shift_id"`
	ShiftID           *string    `json:"shift_id" db:"shift_id"`
	ShiftName         *string    `json:"shift_name" db:"shift_name"`
	ShiftStartTime    *string    `json:"shift_start_time" db:"shift_start_time"`
	ShiftEndTime      *string    `json:"shift_end_time" db:"shift_end_time"`
	AttendanceID      *string    `json:"attendance_id" db:"attendance_id"`
	Status            *string    `json:"status" db:"status"`
	CheckInTime       *time.Time `json:"check_in_time" db:"check_in_time"`
	CheckOutTime      *time.Time `json:"check_out_time" db:"check_out_time"`
	OvertimeHours     *float64   `json:"overtime_hours" db:"overtime_hours"`
	IsLocked          *bool      `json:"is_locked" db:"is_locked"`
	ComputedWage      *float64   `json:"computed_wage" db:"computed_wage"`
}

type LedgerSummaryRange struct {
	JamaTotal   float64 `json:"jama_total" db:"jama_total"`
	UdhaarTotal float64 `json:"udhaar_total" db:"udhaar_total"`
	EntryCount  int32   `json:"entry_count" db:"entry_count"`
}

type EmployeeAttendanceSummary struct {
	Total     int32   `json:"total" db:"total"`
	Present   int32   `json:"present" db:"present"`
	Absent    int32   `json:"absent" db:"absent"`
	HalfDay   int32   `json:"half_day" db:"half_day"`
	PaidLeave int32   `json:"paid_leave" db:"paid_leave"`
	WeekOff   int32   `json:"week_off" db:"week_off"`
	Percent   float64 `json:"percent" db:"percent"`
}

type TenantConfig struct {
	TenantID            string    `json:"tenant_id" db:"tenant_id"`
	OTTrigger           string    `json:"ot_trigger" db:"ot_trigger"`
	OTThresholdHours    float64   `json:"ot_threshold_hours" db:"ot_threshold_hours"`
	OTMultiplierDefault float64   `json:"ot_multiplier_default" db:"ot_multiplier_default"`
	OTRounding          int32     `json:"ot_rounding" db:"ot_rounding"`
	WageBasis           string    `json:"wage_basis" db:"wage_basis"`
	WeekOffPaid         bool      `json:"week_off_paid" db:"week_off_paid"`
	WeeklyOffs          string    `json:"weekly_offs" db:"weekly_offs"`
	CreatedAt           time.Time `json:"created_at" db:"created_at"`
	UpdatedAt           time.Time `json:"updated_at" db:"updated_at"`
}

type StaffProfile struct {
	Employee
	ManagerName  *string `json:"manager_name" db:"manager_name"`
	ManagerPhone *string `json:"manager_phone" db:"manager_phone"`
	ShiftName    *string `json:"shift_name" db:"shift_name"`
	ShiftStart   *string `json:"shift_start_time" db:"shift_start_time"`
	ShiftEnd     *string `json:"shift_end_time" db:"shift_end_time"`
}

type DashboardSnapshot struct {
	TotalStaff       int
	AttendanceCount  int
	Present          int
	Absent           int
	OnLeave          int
	DailyJamaTotal   float64
	WageBillMTD      float64
	TotalOutstanding float64
}

type EmployeeBalance struct {
	EmployeeID string
	Balance    float64
}
