# API Endpoints Documentation — Factory Workforce Management App

## Architecture Overview

```
┌──────────────────────────┐       ┌─────────────────────────┐       ┌───────────┐
│   Flutter App (Dart)     │       │   Go Backend (chi)      │       │ Firebase   │
│                          │       │                          │       │ Auth       │
│  FirebaseAuth.verifyPhone─┼─SMS──┤                          │       │           │
│  signInWithCredential ───┼─ID───┤                          │       │           │
│  ApiClient ──POST /auth──┼─HTTP─┤  chi.Router ─► Controllers │       │           │
│  Riverpod Providers      │       │       │                  │       └───────────┘
│  Premium Screens         │       │   AuthMiddleware +       │
│                          │       │   TenantMiddleware       │
└──────────────────────────┘       └───────────┬──────────────┘
                                                │
                                        ┌───────▼──────┐
                                        │  PostgreSQL   │
                                         │  (17 migrations)│
                                        └──────────────┘
```

### Server
- **Framework**: `go-chi/chi/v5` router
- **Database**: PostgreSQL via `pgx` driver + `goqu` query builder
- **Auth**: Firebase Phone Auth (Google Admin SDK) + HS256 JWT — token set as `auth_token` cookie (HttpOnly) **and** returned in JSON response body as `access_token`
- **Token expiry**: Configurable via `TOKEN_TTL` env var (default 30 days)
- **Port**: `127.0.0.1:8081` (configurable)
- **Response Envelope**: Every API response follows one of three shapes (see below)

### Frontend
- **Framework**: Flutter + Riverpod + Material Design 3
- **Auth**: Firebase Auth (`firebase_core` + `firebase_auth`) for phone verification
- **HTTP Client**: Custom `ApiClient` class wrapping `package:http`
- **Auth Flow**: Firebase ID token exchanged for app JWT → stored in Riverpod `tokenProvider` (StateProvider), sent as `Authorization: Bearer` header
- **Services Layer**: 12 service classes wrapping `ApiClient` calls
- **Screens**: 19 feature screens with premium glassmorphism design

---

## Response Envelope

All JSON responses use a standard 3-status envelope:

```json
// Success (2xx)
{ "status": "success", "data": { ... } }

// Client error — malformed request, missing fields, validation (4xx)
{ "status": "fail", "message": "description of the problem" }

// Server error — internal error (5xx)
{ "status": "error", "message": "description of the problem" }
```

---

## Authentication & Middleware

### Auth Flow (Firebase Phone Auth)

```
LoginScreen
  │
  ├─ FirebaseAuth.verifyPhoneNumber(phone)
  │   ├─ verificationCompleted (auto-retrieval) ──┐
  │   └─ codeSent → user enters OTP ──────────────┤
  │                                               ▼
  │                                   signInWithCredential()
  │                                               │
  │                                   FirebaseAuth.currentUser.getIdToken()
  │                                               │
  └──── POST /api/v1/auth/firebase-login ─────{ id_token }────►
                                                               │
                    Go Backend: VerifyIDToken (Admin SDK)      │
                    Extract phone_number from claims           │
                    Lookup employee/tenant by phone            │
                    Issue app JWT                              │
                    ◄──── { access_token, tenant_id, role } ───┘
```

### JWT Claims (stored in token)
```json
{
  "tenant_id":   "uuid",   // The tenant (factory) the user belongs to
  "employee_id": "uuid",   // The employee record ID (empty for tenant owners)
  "role":        "owner" | "manager" | "employee",
  "exp":         int64,    // Unix timestamp — token expires in TOKEN_TTL hours
  "iat":         int64     // Unix timestamp — issued at
}
```

### Middleware Chain

```
Request ──► RequestLogger ──► Recoverer ──► CORS ──► RouteHandler
                                                       │
                                            AuthMiddleware (if protected):
                                              1. Read "Authorization: Bearer <token>"
                                              2. Fallback: Read "auth_token" cookie
                                              3. Validate HS256 JWT signature
                                              4. Put Claims into context
                                                      │
                                            TenantMiddleware (if protected):
                                              1. Extract tenant_id from Claims
                                              2. Put tenant_id into context
```

### Frontend Auth Flow

```
LoginScreen ──► Firebase verifyPhoneNumber ──► signInWithCredential
       │                                              │
   getIdToken() ◄── FirebaseAuth.currentUser          │
       │                                              │
   POST /firebase-login {id_token}                    │
       │                                              │
   JWT returned ──► tokenProvider.state = jwt   ApiClient.setToken(jwt)
       │                                              │
   AuthGate rebuilds ──► MainShell (authenticated)    All subsequent requests
                                                      include Authorization: Bearer
```

---

## Complete Endpoint Reference

### 1. Health & Swagger (Public — No Auth)

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| `GET` | `/health` | inline | Health check — always returns 200 with body `"ok"` |
| `GET` | `/swagger` | inline | Serves Swagger UI HTML (`./docs/index.html`) |
| `GET` | `/swagger.json` | inline | Serves OpenAPI spec (`./docs/swagger.json`) |

**Frontend**: Not called from Flutter (server ops only).

---

### 2. Auth (Public — No Auth)

#### `POST /api/v1/auth/firebase-login`
Accepts a Firebase ID token (obtained after phone auth), verifies it via Firebase Admin SDK,
looks up the user by phone number, and returns an app JWT.

**Request:**
```json
{ "id_token": "eyJhbGciOiJSUzI1NiIs..." }
```
**Success (200):**
```json
{
  "status": "success",
  "data": {
    "access_token": "eyJhbG...",
    "tenant_id": "uuid",
    "employee_id": "uuid",
    "role": "owner"
  }
}
```
**Failure (400):** missing `id_token`
**Failure (401):** invalid Firebase token or phone not registered

**Frontend**: `AuthService.signInWithFirebase()` → used in `LoginScreen` after Firebase phone auth
completes. Calls `ApiClient.setToken()` with the app JWT on success.

---

#### `POST /api/v1/auth/register`
Creates a new tenant (factory) + first owner employee in one transaction.
Uses Firebase ID token for phone verification.

**Request:**
```json
{
  "name": "Vivek",
  "factory_name": "Vivek Fabrics",
  "id_token": "eyJhbGciOiJSUzI1NiIs..."
}
```
**Success (200):** Same shape as firebase-login — `{ access_token, tenant_id, employee_id, role }`
**Failure (400):** missing required fields
**Failure (401):** invalid Firebase token

**Frontend**: `AuthService.register()` → used in `RegisterScreen`. Calls `ApiClient.setToken()` with
the app JWT on success. Navigates to `/onboarding`.

---

#### `DELETE /api/v1/auth/account`

Deletes the entire tenant account and all associated data (employees, attendance, ledger, shifts, etc.).
**Requires "owner" role** (403 otherwise). Irreversible — no undo.

**Success (200):**
```json
{
  "status": "success",
  "data": {
    "message": "Account deleted"
  }
}
```
**Failure (403):** caller is not the account owner

**Frontend**: `AuthService.deleteAccount()` → confirmation dialog in `MyProfileScreen` with permanent-deletion warning. On success, navigates back to login.

---

### 3. Staff (Auth + Tenant)

All staff endpoints require `AuthMiddleware` + `TenantMiddleware`. Every employee belongs to exactly one tenant.

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| `GET` | `/api/v1/staff` | `staffCtrl.List` | List employees with pagination & search |
| `POST` | `/api/v1/staff` | `staffCtrl.Create` | Add a new employee |
| `GET` | `/api/v1/staff/{id}` | `staffCtrl.Get` | Get single employee |
| `PUT` | `/api/v1/staff/{id}` | `staffCtrl.Update` | Update employee (blocks "employee" role) |
| `DELETE` | `/api/v1/staff/{id}` | `staffCtrl.Delete` | Soft-delete (requires "owner" role) |
| `POST` | `/api/v1/staff/{id}/upload-photo` | `uploadCtrl.UploadPhoto` | Upload photo (jpg/png, max 5MB) |
| `GET` | `/api/v1/staff/{id}/documents` | `uploadCtrl.ListDocuments` | List KYC documents for employee |
| `POST` | `/api/v1/staff/{id}/documents/{type}` | `uploadCtrl.UploadDocument` | Upload/replace KYC doc (aadhaar\|pan\|bank, jpg/png/pdf) |
| `DELETE` | `/api/v1/staff/{id}/documents/{type}` | `uploadCtrl.DeleteDocument` | Delete KYC doc + stored asset |
| `GET` | `/api/v1/staff/{id}/profile` | `staffCtrl.Profile` | Full profile with manager + shift info |
| `PUT` | `/api/v1/staff/{id}/manager` | `staffCtrl.AssignManager` | Set/remove reporting manager |

---

#### `GET /api/v1/staff`

**Query Params:** `limit` (int, max 100, default 20), `offset` (int, default 0), `q` (search string), `status` (filter)

**Success:** Returns array of employee objects:
```json
{
  "status": "success",
  "data": [
    {
      "id": "uuid", "name": "Rahul Sharma", "phone": "+919876543210",
      "designation": "Operator", "wage_type": "daily", "wage_amount": "450",
      "role": "employee", "is_active": true,
      "shift_name": "Morning", "manager_name": "Vivek"
    }
  ]
}
```

**Frontend**: `StaffService.list()` → `StaffDirectoryScreen` (premium listing with alphabet grouping, green/red financial indicators, staggered animations). FAB opens `AddEmployeeScreen`.

---

#### `POST /api/v1/staff`

**Request:**
```json
{
  "name": "Rahul Sharma", "phone": "+919876543210",
  "designation": "Operator", "wage_type": "daily", "wage_amount": "450",
  "daily_target_units": 100,
  "date_of_joining": "2024-01-15", "pan_number": "ABCDE1234F",
  "aadhaar_number": "123412341234", "pf_number": "MH/123/4567",
  "bank_account_number": "00012345678901", "bank_ifsc": "SBIN0001234",
  "upi_id": "rahul@upi", "emergency_contact_name": "Sunita",
  "emergency_contact_phone": "+919000000000", "health_notes": "None",
  "current_address": "Line 1, City", "permanent_address": "Village, Dist"
}
```
**Required:** `name`, `phone`, `wage_type`, `wage_amount`
**Optional KYC:** `date_of_joining`, `pan_number`, `aadhaar_number`, `pf_number`, `bank_account_number`, `bank_ifsc`, `upi_id`, `emergency_contact_name`, `emergency_contact_phone`, `health_notes`, `current_address`, `permanent_address`

**Frontend**: `StaffService.create()` → `AddEmployeeScreen` (premium form with wage type toggle, KYC & Financial section, Emergency & Address section, haptic feedback, glassmorphism fields).

---

#### `GET /api/v1/staff/{id}`

**Path Param:** `id` — Employee UUID
**Success:** Single employee object (same shape as list items, including all KYC fields).

**Frontend**: `StaffService.get()` → `EmployeeProfileScreen` (fetched in `initState`).

---

#### `PUT /api/v1/staff/{id}`

**Request:** Same shape as create. KYC fields are only updated when provided; `null`/omitted values keep the existing value. **Blocks "employee" role** (403).
**Frontend**: `StaffService.update()` → `AddEmployeeScreen` opened in edit mode from profile screen.

---

#### `DELETE /api/v1/staff/{id}`

Soft-deletes (`is_active = false`). **Requires "owner" role** (403 otherwise).
**Frontend**: Not yet wired.

---

#### `POST /api/v1/staff/{id}/upload-photo`

**Multipart:** `file` field, max 5MB, `.jpg`/`.jpeg`/`.png` only.
When Cloudinary is configured (`CLOUDINARY_CLOUD_NAME` + `CLOUDINARY_API_KEY` + `CLOUDINARY_API_SECRET`), the photo is uploaded to the `profiles` folder and `photo_url` is the Cloudinary `secure_url`. Otherwise it is saved to `./uploads/{employeeID}-{random}{ext}` and `photo_url` is `/uploads/{filename}`.

**Success:**
```json
{ "status": "success", "data": { "photo_url": "/uploads/abc-123.jpg", "employee": { ... } } }
```

**Frontend**: Not yet wired.

---

#### `POST /api/v1/staff/{id}/documents/{type}`

**Path:** `type` must be `aadhaar`, `pan`, or `bank` (one slot per type — uploading replaces).
**Multipart:** `file` field, max 5MB, `.jpg`/`.jpeg`/`.png`/`.pdf` only.
**Blocks "employee" role** (403). Stored in Cloudinary (`kyc/{employeeID}` folder, deterministic public id) when configured; otherwise `./uploads/`.
Deletes the previous asset when replacing.

**Success:**
```json
{ "status": "success", "data": { "id": "uuid", "doc_type": "aadhaar", "file_path": "https://res.cloudinary.com/.../kyc/abc/aadhaar.jpg", "public_id": "kyc/abc/aadhaar", "original_name": "aadhaar.jpg" } }
```

---

#### `GET /api/v1/staff/{id}/documents`

Returns array of `{ id, doc_type, file_path, public_id, original_name, uploaded_at }` for the employee.

---

#### `DELETE /api/v1/staff/{id}/documents/{type}`

Deletes the document record and removes the stored asset (Cloudinary destroy or local file). **Blocks "employee" role** (403). Returns 404 if no document exists.

**Frontend**: `DocumentService` → `_DocumentVault` in `EmployeeProfileScreen` Info & KYC tab (3 cards: Aadhaar / PAN / Bank Passbook, camera/gallery/PDF picker, thumbnail, view, delete).

---

#### `GET /api/v1/staff/{id}/profile`

Returns extended profile with manager info and default shift details.

**Success:**
```json
{
  "status": "success",
  "data": {
    "id": "uuid", "name": "Rahul Sharma", "phone": "...",
    "designation": "...", "wage_type": "...", "wage_amount": "450",
    "role": "employee", "is_active": true,
    "manager_name": "Vivek", "shift_name": "Morning",
    "shift_start_time": "08:00", "shift_end_time": "17:00"
  }
}
```

**Frontend**: `StaffService.getProfile()` → `EmployeeProfileScreen` (merged with `get()` data in `initState`).

---

#### `PUT /api/v1/staff/{id}/manager`

**Request:** `{ "manager_id": "uuid" }` — set to empty string to unassign.
**Blocks "employee" role** (403).

**Frontend**: Not yet wired.

---

### 4. Me (Auth + Tenant — Self-Service)

All `/api/v1/me` endpoints use the authenticated user's `employee_id` from JWT claims. No URL params needed for identity.

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| `GET` | `/api/v1/me` | `meCtrl.Profile` | Own profile (same as staff profile) |
| `GET` | `/api/v1/me/attendance` | `meCtrl.Attendance` | Own attendance records within date range |
| `GET` | `/api/v1/me/ledger` | `meCtrl.Ledger` | Own ledger entries + current balance |
| `GET` | `/api/v1/me/payslip` | `meCtrl.Payslip` | Download PDF payslip |
| `POST` | `/api/v1/me/advance-request` | `meCtrl.RequestAdvance` | Request an advance/salary advance |

---

#### `GET /api/v1/me`

Returns the authenticated user's full profile (staff profile shape).

**Frontend**: Called in `MyProfileScreen` using `ApiClient.get('/api/v1/me')` directly. Shows name, phone, role, factory name, and sign-out button.

---

#### `GET /api/v1/me/attendance`

**Query Params:** `start_date`, `end_date` (YYYY-MM-DD)
Returns array of attendance records for the authenticated employee.

**Frontend**: Not yet wired (future: employee self-service attendance view).

---

#### `GET /api/v1/me/ledger`

**Query Params:** `start_date`, `end_date` (YYYY-MM-DD)

**Success:**
```json
{
  "status": "success",
  "data": {
    "entries": [ { "id": "uuid", "type": "jama", "amount": 450, ... } ],
    "balance": 2700
  }
}
```

**Frontend**: Not yet wired (future: employee self-service ledger view).

---

#### `GET /api/v1/me/payslip`

**Query Params:** `start_date`, `end_date` (YYYY-MM-DD)
Returns raw PDF bytes with `Content-Type: application/pdf`.

**Frontend**: Not yet wired.

---

#### `POST /api/v1/me/advance-request`

**Request:** `{ "amount": "2000", "note": "Need advance for supplies" }`

**Frontend**: Not yet wired (future: employee self-service advance request).

---

### 5. Shifts (Auth + Tenant)

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| `GET` | `/api/v1/shifts` | `shiftCtrl.List` | List all shifts for tenant |
| `POST` | `/api/v1/shifts` | `shiftCtrl.Create` | Create a shift |
| `GET` | `/api/v1/shifts/{id}` | `shiftCtrl.Get` | Get single shift |
| `PUT` | `/api/v1/shifts/{id}` | `shiftCtrl.Update` | Update shift |
| `DELETE` | `/api/v1/shifts/{id}` | `shiftCtrl.Delete` | Delete shift (fails if assigned to employee) |

---

#### `GET /api/v1/shifts`

**Success:**
```json
{
  "status": "success",
  "data": [
    {
      "id": "uuid", "name": "Morning", "start_time": "08:00", "end_time": "17:00",
      "crosses_midnight": false, "grace_period_minutes": 15, "is_default": true
    }
  ]
}
```

**Frontend**: `ShiftService.list()` → `shiftsListProvider` → `ShiftsManagementScreen` (premium CRUD list with staggered slide-in cards, edit/delete actions).

---

#### `POST /api/v1/shifts`

**Request:** `{ "name": "Morning", "start_time": "08:00", "end_time": "17:00", "grace_period_minutes": 15, "crosses_midnight": false, "is_default": false }`
**Required:** `name`, `start_time`, `end_time`

**Frontend**: `ShiftService.create()` → `_ShiftFormDialog` (dialog with time inputs, grace period, toggle switches).

---

#### `GET /api/v1/shifts/{id}`

Single shift object (same shape as list).

**Frontend**: `ShiftService.get()` → used by `ShiftsManagementScreen` for editing.

---

#### `PUT /api/v1/shifts/{id}`

Same shape as create.

**Frontend**: `ShiftService.update()` → `_ShiftFormDialog` (pre-populated with existing shift data).

---

#### `DELETE /api/v1/shifts/{id}`

Returns 500 if shift is still assigned as default shift to any employee.

**Frontend**: `ShiftService.delete()` → confirmation dialog → refetch list.

---

### 6. Attendance (Auth + Tenant)

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| `GET` | `/api/v1/attendance` | `attCtrl.ListByDate` | All attendance for a date |
| `GET` | `/api/v1/attendance/{id}` | `attCtrl.ListByEmployee` | Employee attendance within date range |
| `POST` | `/api/v1/attendance` | `attCtrl.Create` | Create single attendance record |
| `PUT` | `/api/v1/attendance/{id}` | `attCtrl.Update` | Update attendance record |
| `POST` | `/api/v1/attendance/bulk` | `attCtrl.BulkUpsert` | Batch upsert attendance records |
| `POST` | `/api/v1/attendance/lock` | `attCtrl.LockMonth` | Lock attendance for a date range |

---

#### `GET /api/v1/attendance`

**Query Params:** `date` (required, YYYY-MM-DD)

**Success:**
```json
{
  "status": "success",
  "data": [
    {
      "id": "uuid", "employee_id": "uuid", "employee_name": "Rahul Sharma",
      "date": "2026-10-24", "shift_id": "uuid", "status": "present",
      "check_in_time": "2026-10-24T08:05:00Z", "check_out_time": "2026-10-24T17:00:00Z",
      "overtime_hours": 0.0, "computed_wage": 450.0, "is_locked": false
    }
  ]
}
```
**Valid status values:** `present`, `absent`, `half_day`, `paid_leave`, `week_off`

**Frontend**: `AttendanceService.listByDate()` → `todayAttendanceProvider` → `AttendanceRosterPage` (bottom nav tab 2 — daily roster with segmented status buttons).

---

#### `GET /api/v1/attendance/{id}`

**Path Param:** `id` — Employee UUID
**Query Params:** `start_date`, `end_date` (required)

**Frontend**: `AttendanceService.listByEmployee()` → not yet wired in a dedicated screen.

---

#### `POST /api/v1/attendance`

**Required:** `employee_id`, `date` (YYYY-MM-DD), `shift_id`, `status`
**Optional:** `check_in_time`, `check_out_time` (RFC3339), `overtime_hours`, `overtime_rate_multiplier`, `units_produced`

**Frontend**: `AttendanceService.create()` → not yet wired (status buttons on `AttendanceRosterPage` are not yet calling create).

---

#### `PUT /api/v1/attendance/{id}`

Updates `shift_id`, `status`, `check_in_time`, `check_out_time`, `overtime_hours`, `overtime_rate_multiplier`, `units_produced`.

**Frontend**: `AttendanceService.update()` → not yet wired.

---

#### `POST /api/v1/attendance/bulk`

**Request:**
```json
{
  "records": [
    { "employee_id": "uuid", "date": "2026-10-24", "shift_id": "uuid", "status": "present" },
    { "employee_id": "uuid", "date": "2026-10-24", "shift_id": "uuid", "status": "absent" }
  ]
}
```
All-or-nothing: entire batch is rolled back if any record fails.

**Frontend**: `AttendanceService.bulkUpsert()` → not yet wired (future: "Mark All Present" button).

---

#### `POST /api/v1/attendance/lock`

**Request:** `{ "start_date": "2026-10-01", "end_date": "2026-10-31" }`
Once locked, modifications to those records are rejected.

**Frontend**: `AttendanceService.lockMonth()` → not yet wired.

---

### 7. Ledger (Auth + Tenant)

The ledger tracks two transaction types:
- **`jama`** (credit) — wage added, usually positive amount
- **`udhaar`** (debit) — advance taken, positive amount (adds to outstanding)

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| `POST` | `/api/v1/ledger` | `ledgerCtrl.CreateEntry` | Create a ledger entry |
| `GET` | `/api/v1/ledger` | `ledgerCtrl.ListByTenant` | All entries across tenant in date range |
| `GET` | `/api/v1/ledger/total-outstanding` | `ledgerCtrl.GetTotalOutstanding` | Total outstanding across all employees |
| `GET` | `/api/v1/ledger/{id}` | `ledgerCtrl.ListByEmployee` | Entries for one employee in date range |
| `GET` | `/api/v1/ledger/{id}/balance` | `ledgerCtrl.GetBalance` | Current balance for one employee |
| `POST` | `/api/v1/ledger/{id}/settle` | `ledgerCtrl.SettleAccount` | Zero-out an employee's balance |

---

#### `POST /api/v1/ledger`

**Request:**
```json
{
  "employee_id": "uuid", "date": "2026-10-24",
  "type": "jama" | "udhaar", "amount": "450", "note": "Daily wage"
}
```
**Required:** `employee_id`, `date`, `type` (must be `"jama"` or `"udhaar"`), `amount`

**Frontend**: `LedgerService.create()` → `NewLedgerEntryScreen` (premium color-shifting Jama/Udhaar toggle, macro-typography amount input, haptic feedback).

---

#### `GET /api/v1/ledger`

**Query Params:** `start_date`, `end_date` (required)

**Success:**
```json
{
  "status": "success",
  "data": [
    { "id": "uuid", "employee_id": "uuid", "employee_name": "Rahul Sharma",
      "date": "2026-10-24", "type": "jama", "amount": 450.0, "note": "Daily wage" }
  ]
}
```

**Frontend**: `LedgerService.listByTenant()` → `ledgerListProvider` → `LedgerListScreen` (bottom nav tab 3 — glassmorphism summary card, staggered rows, green/red color-coding).

---

#### `GET /api/v1/ledger/total-outstanding`

**Success:** `{ "status": "success", "data": { "total_outstanding": 42600.0 } }`

**Frontend**: `LedgerService.getSummary()` → `LedgerSummary` model → used in `LedgerListScreen` summary card.

---

#### `GET /api/v1/ledger/{id}`

**Path Param:** `id` — Employee UUID
**Query Params:** `start_date`, `end_date` (required)

**Frontend**: `LedgerService.listByEmployee()` → used in `EmployeeProfileScreen` ledger tab (currently mock data).

---

#### `GET /api/v1/ledger/{id}/balance`

Returns `{ "status": "success", "data": { "balance": int32 } }`

**Frontend**: `LedgerService.getBalance()` → used in `EmployeeProfileScreen` (currently mock).

---

#### `POST /api/v1/ledger/{id}/settle`

**Request:** `{ "date": "2026-10-31" }`
Creates a settlement entry that zeros the employee's balance.

**Frontend**: `LedgerService.settleAccount()` → not yet wired (future: "F&F Settle" button in `EmployeeProfileScreen`).

---

### 8. Sync Queue (Auth + Tenant)

Offline-sync infrastructure for mobile workers. Not yet used from Flutter.

| Method | Path | Handler |
|--------|------|---------|
| `POST` | `/api/v1/sync` | `syncCtrl.CreateEvent` |
| `GET` | `/api/v1/sync/pending` | `syncCtrl.ListPending` |
| `PUT` | `/api/v1/sync/status` | `syncCtrl.UpdateStatus` |

**Frontend**: No wiring (future: offline-first sync feature).

---

### 9. Holidays (Auth + Tenant)

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| `POST` | `/api/v1/holidays` | `holidayCtrl.Create` | Add a holiday |
| `GET` | `/api/v1/holidays` | `holidayCtrl.List` | List all holidays |
| `DELETE` | `/api/v1/holidays/{id}` | `holidayCtrl.Delete` | Remove a holiday |

---

#### `POST /api/v1/holidays`

**Request:** `{ "name": "Diwali", "date": "2026-10-31" }`

**Frontend**: `HolidayService.create()` → `HolidaysScreen` (premium list with staggered cards, date picker dialog, recurring toggle).

---

#### `GET /api/v1/holidays`

**Success:** `{ "status": "success", "data": [{ "id": "uuid", "name": "Diwali", "date": "2026-10-31", "is_recurring": false }] }`

**Frontend**: `HolidayService.list()` → `holidaysListProvider` → `HolidaysScreen`.

---

#### `DELETE /api/v1/holidays/{id}`

**Frontend**: `HolidayService.delete()` → confirmation dialog → refetch list.

---

### 10. Leave Policies (Auth + Tenant)

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| `GET` | `/api/v1/leave-policies` | `leavePolicyCtrl.Get` | Get current leave policy (404 if not set) |
| `PUT` | `/api/v1/leave-policies` | `leavePolicyCtrl.Upsert` | Create or update leave policy |

---

#### `GET /api/v1/leave-policies`

**Success:** `{ "status": "success", "data": { "paid_leave_days_per_year": 12, "unpaid_leave_days_per_year": 0 } }`
**404:** `{ "status": "fail", "message": "Leave policy not found" }`

**Frontend**: `LeavePolicyService.get()` → `leavePolicyProvider` → `LeavePolicyScreen` (premium config form with gradient header, numeric fields).

---

#### `PUT /api/v1/leave-policies`

**Request:** `{ "paid_leave_days_per_year": 12, "unpaid_leave_days_per_year": 0 }`
Both must be non-negative.

**Frontend**: `LeavePolicyService.upsert()` → save button → refetch.

---

### 11. Reports (Auth + Tenant)

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| `GET` | `/api/v1/reports/daily` | `reportCtrl.DailySummary` | Daily attendance + wage summary |
| `GET` | `/api/v1/reports/employee-monthly` | `reportCtrl.EmployeeMonthly` | Per-employee monthly report |
| `GET` | `/api/v1/reports/wage-bill-trends` | `reportCtrl.WageBillTrends` | Multi-month wage bill trends |
| `GET` | `/api/v1/reports/defaulters` | `reportCtrl.DefaultersList` | Employees with outstanding > wage |
| `GET` | `/api/v1/reports/export` | `reportCtrl.ExportCSV` | CSV export (defaulters or trends) |

---

#### `GET /api/v1/reports/daily`

**Query Params:** `date` (required, YYYY-MM-DD)

**Success:**
```json
{
  "status": "success",
  "data": {
    "total_workers": 25, "present": 22, "absent": 2, "on_leave": 1,
    "total_wage_bill": 9900.0
  }
}
```

**Frontend**: `ReportService.dailySummary()` → `dailySummaryProvider` → `DailySummaryScreen` (premium hero card with animated progress bar, stat tiles, wage bill display).

---

#### `GET /api/v1/reports/employee-monthly`

**Query Params:** `employee_id` (required), `start_date`, `end_date` (required, YYYY-MM-DD)

**Frontend**: `ReportService.employeeMonthly()` → navigation target from `ReportsHubScreen`.

---

#### `GET /api/v1/reports/wage-bill-trends`

**Query Params:** `months` (optional, default 6, max 24)

**Success:** Array of `{ "month": "2026-04", "total_wages": 185000.0, "headcount": 22 }`

**Frontend**: `ReportService.wageBillTrends()` → navigation target from `ReportsHubScreen`.

---

#### `GET /api/v1/reports/defaulters`

**Success:** Array of `{ "employee_id": "uuid", "name": "Rahul Sharma", "phone": "...", "outstanding_balance": 4500.0, "monthly_wage": 9900.0 }`

**Frontend**: `ReportService.defaulters()` → `defaultersProvider` → `DefaultersScreen` (premium red-accented cards with outstanding amounts, employee initials avatars, empty state with checkmark).

---

#### `GET /api/v1/reports/export`

**Query Params:** `type` (required — `"defaulters"` or `"trends"`), `months` (optional for trends)
**Response:** `Content-Type: text/csv` with `Content-Disposition: attachment`

**Frontend**: Not yet wired.

---

### 12. Dashboard (Auth + Tenant)

#### `GET /api/v1/dashboard`

**Success:**
```json
{
  "status": "success",
  "data": {
    "total_staff": 25, "present": 22, "absent": 2, "on_leave": 1,
    "daily_jama_total": 9900.0, "total_outstanding": 42600.0,
    "recent_activity": [
      { "action": "employee_created", "entity_type": "Rahul Sharma joined",
        "created_at": "2026-10-24T10:30:00Z" }
    ]
  }
}
```

**Frontend**: `DashboardService.get()` → `DashboardData.fromJson()` → `DashboardScreen` (bottom nav tab 0 — premium glassmorphism stat cards, macro-typography attendance percentage, animated progress bar, GSAP-style sweep, duotone icons).

Note: `DashboardData.fromJson` maps backend field names:
```
total_staff      → totalWorkforce
present          → presentToday
absent           → absentToday
on_leave         → onLeave
daily_jama_total → totalJama
total_outstanding→ totalUdhaar
```

Attendance percentage is computed: `present / total_staff * 100`

---

### 13. Advance Requests (Auth + Tenant)

Admin version — requires explicit `employee_id` (unlike `/me/advance-request` which uses JWT).

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| `POST` | `/api/v1/advance-requests` | `advReqCtrl.Create` | Create advance for any employee |
| `GET` | `/api/v1/advance-requests` | `advReqCtrl.List` | List, optionally filtered by status |
| `PUT` | `/api/v1/advance-requests/{id}/approve` | `advReqCtrl.Approve` | Approve + auto-create ledger entry |
| `PUT` | `/api/v1/advance-requests/{id}/deny` | `advReqCtrl.Deny` | Deny request |

---

#### `GET /api/v1/advance-requests`

**Query Params:** `status` (optional — `"pending"`, `"approved"`, `"denied"`)

**Success:**
```json
{
  "status": "success",
  "data": [
    {
      "id": "uuid", "employee_id": "uuid", "employee_name": "Rahul Sharma",
      "amount": 2000.0, "reason": "Supplies", "status": "pending",
      "created_at": "2026-10-24T10:30:00Z"
    }
  ]
}
```

**Frontend**: `AdvanceRequestService.list()` → `advanceRequestsProvider` → `AdvanceRequestsScreen` (premium cards with pending/approved/denied color badges, tap to approve/deny).

---

#### `POST /api/v1/advance-requests`

**Request:** `{ "employee_id": "uuid", "amount": "2000", "note": "Supplies" }`

**Frontend**: `AdvanceRequestService.create()` → not yet wired.

---

#### `PUT /api/v1/advance-requests/{id}/approve`

**Request:** `{ "date": "2026-10-24" }`
Auto-creates a ledger entry of type `udhaar` for the approved amount.

**Frontend**: `AdvanceRequestService.approve()` → `AdvanceRequestsScreen` approve dialog → refetch list.

---

#### `PUT /api/v1/advance-requests/{id}/deny`

**Frontend**: `AdvanceRequestService.deny()` → `AdvanceRequestsScreen` deny dialog → refetch list.

---

### 14. Payroll (Auth + Tenant)

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| `POST` | `/api/v1/payroll/calculate` | `payrollCtrl.Calculate` | Calculate payroll for all employees in date range |
| `POST` | `/api/v1/payroll/payslip` | `payrollCtrl.GeneratePayslip` | Generate PDF payslip for one employee |
| `POST` | `/api/v1/payroll/lock` | `payrollCtrl.LockMonth` | Lock payroll for date range |

---

#### `POST /api/v1/payroll/calculate`

**Request:** `{ "start_date": "2026-10-01", "end_date": "2026-10-31" }`

**Success:** Returns calculated payroll data with per-employee breakdown.

**Frontend**: `PayrollService.calculate()` → `PayrollPreviewScreen` (currently mocked — emerald "Lock & Generate Slips" button, glassmorphism summary card, editable net adjustment rows).

---

#### `POST /api/v1/payroll/payslip`

**Request:** `{ "employee_id": "uuid", "start_date": "2026-10-01", "end_date": "2026-10-31" }`
**Response:** Raw PDF bytes with `Content-Type: application/pdf`.

**Frontend**: `PayrollService.generatePayslip()` → not yet wired (future: "Generate Slip" button in `EmployeeProfileScreen` bottom bar).

---

#### `POST /api/v1/payroll/lock`

**Request:** `{ "start_date": "2026-10-01", "end_date": "2026-10-31", "adjustments": [{ "employee_id": "uuid", "net_pay": 9500 }] }`

`adjustments` is optional; when provided, the `net_pay` value overrides the calculated net for the matching employee. The endpoint writes `wage` ledger entries (using adjusted net) for every employee in the period, then locks the attendance month.

**Frontend**: `PayrollService.lockMonth()` → `PayrollPreviewScreen` lock button ("Lock & Generate Slips").

---

### 15. Settings — Payroll (Auth + Tenant)

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| `GET` | `/api/v1/settings/payroll` | `settingsCtrl.GetPayrollSettings` | Get payroll config (returns defaults if none set) |
| `PUT` | `/api/v1/settings/payroll` | `settingsCtrl.UpsertPayrollSettings` | Upsert payroll config |

---

#### `GET /api/v1/settings/payroll`

**Success:**
```json
{
  "status": "success",
  "data": {
    "ot_trigger": "after_shift_end", "ot_threshold_hours": 0,
    "ot_multiplier_default": 1.5, "ot_rounding": 30,
    "wage_basis": "calendar", "week_off_paid": false,
    "weekly_offs": "0,6"
  }
}
```

**Frontend**: `SettingsService.getPayrollSettings()` → `payrollSettingsProvider` → `PayrollSettingsScreen` (premium form with OT trigger, multiplier, rounding, wage basis toggle, gradient header).

---

#### `PUT /api/v1/settings/payroll`

**Request:** `{ "ot_trigger": "after_shift_end", "ot_threshold_hours": 0, "ot_multiplier_default": 1.5, "ot_rounding": 30, "wage_basis": "calendar", "week_off_paid": false, "weekly_offs": "0,6" }`

**Validation:**
- `ot_trigger`: must be `"after_shift_end"` or `"after_daily_hours"`
- `ot_multiplier_default`: must be `1.0`, `1.5`, or `2.0`
- `ot_rounding`: must be `15`, `30`, or `60`
- `wage_basis`: must be `"calendar"`, `"fixed_26"`, or `"fixed_30"`
- `weekly_offs`: comma-separated weekday numbers (0=Sunday, 6=Saturday), e.g. `"0,6"`

**Frontend**: `SettingsService.upsertPayrollSettings()` → save button → refetch.

---

### 16. Uploads

| Method | Path | Middleware | Description |
|--------|------|-----------|-------------|
| `GET` | `/uploads/{file}` | Auth + Tenant | Serve uploaded photo files |

Serves static files from `./uploads/` directory. The `{file}` param is the filename stored on the employee's `photo_url` field.

---

## Frontend Service Layer Summary

| Service File | Backend Group | Methods |
|-------------|---------------|---------|
| `auth_service.dart` | Auth | `signInWithFirebase()`, `register()`, `logout()`, `deleteAccount()` |
| `staff_service.dart` | Staff | `list()`, `get()`, `create()`, `update()`, `delete()`, `getProfile()`, `assignManager()` |
| `attendance_service.dart` | Attendance | `listByDate()`, `listByEmployee()`, `create()`, `update()`, `bulkUpsert()`, `lockMonth()` |
| `shift_service.dart` | Shifts | `list()`, `get()`, `create()`, `update()`, `delete()` |
| `ledger_service.dart` | Ledger | `listByTenant()`, `listByEmployee()`, `create()`, `getSummary()`, `getBalance()`, `settleAccount()` |
| `dashboard_service.dart` | Dashboard | `get()` |
| `report_service.dart` | Reports | `dailySummary()`, `employeeMonthly()`, `wageBillTrends()`, `defaulters()` |
| `holiday_service.dart` | Holidays | `list()`, `create()`, `delete()` |
| `leave_policy_service.dart` | Leave Policies | `get()`, `upsert()` |
| `advance_request_service.dart` | Advance Requests | `list()`, `create()`, `approve()`, `deny()` |
| `payroll_service.dart` | Payroll | `calculate()`, `generatePayslip()`, `lockMonth()` |
| `settings_service.dart` | Settings | `getPayrollSettings()`, `upsertPayrollSettings()` |

---

## Frontend Screen Map

| Route | Screen | Backend Endpoint(s) | Status |
|-------|--------|---------------------|--------|
| `/` (root) | `AuthGate` → `LoginScreen` | Firebase Phone Auth → `POST /firebase-login` | ✅ Wired |
| `/register` | `RegisterScreen` | Firebase Phone Auth → `POST /auth/register` | ✅ Wired |
| `/home` | `MainShell` (bottom nav) | — | ✅ Built |
| `/home` tab 0 | `DashboardScreen` | `GET /dashboard` | ✅ Wired |
| `/home` tab 1 | `StaffDirectoryScreen` | `GET /staff` | ✅ Wired |
| `/add_employee` | `AddEmployeeScreen` | `POST /staff` | ✅ Wired |
| `/employee/{id}` | `EmployeeProfileScreen` | `GET /staff/{id}`, `GET /staff/{id}/profile` | ✅ Wired |
| `/home` tab 2 | `AttendanceRosterPage` | `GET /attendance?date=` | ✅ Wired |
| `/home` tab 3 | `LedgerListScreen` | `GET /ledger`, `GET /ledger/total-outstanding` | ✅ Wired |
| `/new_ledger` | `NewLedgerEntryScreen` | `POST /ledger` | ✅ Wired |
| `/home` tab 4 | `ReportsHubScreen` | — (navigation hub) | ✅ Built |
| `/reports/daily-summary` | `DailySummaryScreen` | `GET /reports/daily` | ✅ Wired |
| `/reports/employee-monthly` | *(placeholder)* | `GET /reports/employee-monthly` | 🚧 Route target |
| `/reports/wage-bill-trends` | *(placeholder)* | `GET /reports/wage-bill-trends` | 🚧 Route target |
| `/reports/defaulters` | `DefaultersScreen` | `GET /reports/defaulters` | ✅ Wired |
| `/reports/payroll` | `PayrollPreviewScreen` | `POST /payroll/calculate` | 🚧 Mock data |
| `/shifts` | `ShiftsManagementScreen` | `GET/POST/PUT/DELETE /shifts` | ✅ Wired |
| `/holidays` | `HolidaysScreen` | `GET/POST/DELETE /holidays` | ✅ Wired |
| `/advance-requests` | `AdvanceRequestsScreen` | `GET /advance-requests`, approve/deny | ✅ Wired |
| `/leave-policy` | `LeavePolicyScreen` | `GET/PUT /leave-policies` | ✅ Wired |
| `/payroll-settings` | `PayrollSettingsScreen` | `GET/PUT /settings/payroll` | ✅ Wired |
| `/my-profile` | `MyProfileScreen` | `GET /me` | ✅ Wired |
| `/onboarding` | `OnboardingWizard` | — (UI only, 4-step wizard) | ✅ Built |

**Key:** ✅ = Fully wired with backend, 🚧 = Route exists but not yet connected to live data

---

## Database Schema (17 Migrations)

The database has 17 goose migrations creating:
- `tenants` — factory accounts
- `employees` — worker profiles with wage config
- `shifts` — shift templates (start/end time, grace period, cross-midnight)
- `attendance` — daily attendance records per employee
- `ledger_entries` — jama/udhaar financial transactions
- `advance_requests` — salary advance requests with approval workflow
- `holidays` — tenant-specific holidays
- `leave_policies` — paid/unpaid leave configuration
- `sync_queue` — offline-sync event buffer
- `tenant_config` — payroll settings (OT rules, wage basis, rounding, weekly offs)

---
