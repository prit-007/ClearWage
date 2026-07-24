# Workforce Management SaaS - Detailed V1 Architecture & Page Map

This document outlines the complete V1 blueprint for the Flutter mobile application, encompassing both the **Owner/Supervisor Engine** and the **Employee Read-Only App**.

---

## Part 1: The Owner / Supervisor App (Core Engine)

*Built for speed, offline capability, and factory-floor realities.*

### 1. Initialization & Authentication Flow

- **Page 1.1: Splash Screen**
    - **UI:** Animated company logo.
    - **Logic:** Initializes Isar/SQLite local DB, checks network connectivity, and validates JWT token. Routes to Dashboard or Login.
- **Page 1.2: Login / OTP Screen**
    - **UI:** Phone Number input, "Get OTP" button, 4-digit OTP input (auto-read SMS).
    - **Logic:** Authenticates via Golang API. Fetches `tenant_id` configuration and role (`admin` vs `supervisor`). Performs initial DB sync.

### 2. Tab 1: Home (Dashboard)

*The command center for instant daily overviews.*

- **Top Bar:** Company Name, Sync Status Icon (Cloud ✓ or Cloud ✕), Language Toggle (English / ગુજરાતી / हिन्दी).
- **Overview Cards (Horizontal Scroll):**
    - *Attendance Card:* "Today's Workforce: 45/50 Present".
    - *Financial Card:* "Jama Given Today: ₹4,500".
- **Quick Actions Grid (2x2):**
    - `[ + Add Staff ]` -> Opens Add Employee Form.
    - `[ ⏱️ Mark Attendance ]` -> Opens Daily Roster.
    - `[ 💸 Add Jama/Udhaar ]` -> Opens Ledger Entry Modal.
    - `[ 📢 Broadcast Message ]` -> Triggers WhatsApp `url_launcher` to iterate through active staff.
- **Recent Activity Feed:** Read-only list of the last 5 actions (e.g., "Ramesh - Marked Present").

### 3. Tab 2: Staff Directory & Profiles

*The "Red/Green" view, replacing bloated paper files.*

- **Top Bar:** Search Box (Name/Phone) and Filter Icon (Department/Status).
- **List View (Staff):**
    - Avatar, Name, Designation.
    - *Financial Indicator:* 🔴 Red (Company owes employee) or 🟢 Green (Employee owes company).
- **Floating Action Button:** `[ + Add Employee ]`

**Sub-Page: Add/Edit Employee Form (30-Sec Onboarding)**

- **Section 1: Basic Info (Mandatory):** Name, Mobile Number, Wage Type (Fixed/Daily), Wage Amount.
- **Section 2: Employment & KYC Vault (Optional):** Date of Joining, PAN Number, Aadhaar Number, PF Number. Include `[ Upload Photo ]` buttons to capture ID cards securely.
- **Section 3: Bank Details (Optional):** Account Number, IFSC, UPI ID.

**Sub-Page: Employee Profile (Detailed View)**

- **Header:** Photo, Name, Phone, and Quick Action buttons (Call, WhatsApp).
- **Tabbed Interface:**
    - *Info Tab:* Demographics and KYC Vault.
    - *Attendance Tab:* Monthly calendar (Green=Present, Red=Absent, Yellow=Half-day).
    - *Ledger Tab:* Mini-statement of personal Jama/Udhaar.
    - *Audit Log (Owner Only):* View historical edits/deletions.
- **Action Bar:** `[ Settle Account ]` for Full & Final (F&F) settlement.

### 4. Tab 3: Daily Attendance Roster (Fast-Tap)

*Optimized for rapid floor operations and offline use.*

- **Top Bar:** Date Picker (defaults to Today), Shift Selector.
- **List View (Active Staff):** Name and Photo.
    - *Action Row:* Segmented buttons `[ P ]`, `[ A ]`, `[ HD ]`. Taps save instantly to local DB.
    - *OT Field:* Numeric input (e.g., "+ 2 hrs").
- **Footer:** `[ Submit Roster ]`.
- **Offline Logic:** Un-synced records trigger a red Sync Status icon on the Dashboard. App auto-syncs to Golang API when network restores.

### 5. Tab 4: Ledger (Global Jama/Udhaar)

*The core financial engine.*

- **Top Bar:** Month/Year selector.
- **Metric (Owner Only):** Total Outstanding Company Advances. (Hidden from Supervisors).
- **List View:** Chronological feed of all financial entries.
- **Floating Action Button:** `[ + New Entry ]`
    - *Modal:* Select Employee -> Select Type (Jama/Udhaar) -> Amount -> Note -> `[ Save ]`.

### 6. Tab 5: Reports Hub (Owner Exclusive)

*Hidden from Supervisor roles.*

- **Wage Bill Trends:** Graph showing payroll cost month-over-month.
- **Defaulters List:** Filters employees whose outstanding Jama exceeds their monthly salary.
- **Export:** `[ Download CSV ]` for Tally/Accountant export.

### 7. Tab 6: Settings & Sync Center

- **Profile:** Logged-in user and Company Details.
- **Policies & Automations:**
    - *Shift Configuration:* Default timings and late grace periods.
    - *Overtime Multiplier:* 1x, 1.5x, or 2x rate toggles.
    - *Holiday Calendar:* Pre-mark factory closures for automated "Paid Leave" roster filling.
- **Sync Center:** Displays "X items pending sync". Includes a `[ Force Sync Now ]` button.

---

## Part 2: The Employee App (Read-Only Interface)

*A transparent, trust-building interface for the workforce.*

### 1. Authentication (Role-Based Routing)

- **Login Flow:** Same exact Login/OTP screen as the Owner app.
- **Logic:** The Golang backend detects the phone number belongs to an `employee` role and automatically serves this restricted UI instead of the Admin app.

### 2. Tab 1: My Dashboard

- **Overview:** Displays active Wage Rate, current Supervisor Name.
- **Financial Highlight:** Massive, clear indicator of current Jama/Udhaar balance.
- **Action:** `[ Request Advance ]` button (Sends a push notification to Supervisor's app).

### 3. Tab 2: My Calendar (Attendance)

- **UI:** Visual calendar mapping the current month.
- **Logic:** Read-only viewing of Green (Present), Red (Absent), and Yellow (Half-Day) dots.
- **Dispute Mechanism:** `[ Report Error ]` button next to daily logs. Sends an alert to the Supervisor for review, preventing month-end conflicts.

### 4. Tab 3: My Payslips

- **UI:** Vertical list of past months.
- **Logic:** Tapping a month triggers a direct download of the server-generated PDF salary slip.

---

## Part 3: Core Automated Workflows (Both Apps)

### A. The "X-Factor" WhatsApp Dispatch

- **Location:** Found in Employee Profiles, Payroll Generation, and Dashboard Actions.
- **Logic:** Uses Flutter's `url_launcher`.
- **Execution:**
    1. Flutter constructs native text: *"નમસ્તે [Name], આ મહિનાનો તમારો પગાર [Salary] છે અને બાકી જમા [Balance] છે."*
    2. Opens `whatsapp://send?phone=[Number]&text=[EncodedString]`.
    3. Supervisor hits "Send" at zero API cost to the business.

### B. Payroll Generation & Locking

- **Trigger:** End of month, Owner goes to Ledger/Reports -> "Generate Payroll".
- **Logic:** Golang backend calculates (Days worked × Daily Rate) + Overtime - Udhaar.
- **Locking:** Once the Owner taps `[ Lock & Generate ]`, attendance for that month becomes read-only globally. PDFs are generated and stored securely on the Hetzner VPS.

## Part 4: The Super Admin Portal (Platform Owner)

*This is a separate, highly restricted web portal or hidden app route strictly for you (the SaaS owner) to manage the business side of the platform.*[cite: 1]

### 1. Tenant & Subscription Management

- **Page: Companies Dashboard**[cite: 1]
    - **List View:** Displays all registered companies (tenants) currently using your app.
    - **Metrics:** Total active companies, total active employees across the platform.
- **Action Controls:**
    - `[ Activate / Suspend ]` button for each tenant.[cite: 1] If a factory owner stops paying their SaaS subscription, you can suspend their workspace, instantly locking their app access.

---

## Part 5: UI/Field Additions to Existing Pages (From Competitor Analysis)

### 1. Additions to Tab 2: Add/Edit Employee Form & Profile

*In addition to Basic Info, KYC, and Bank Details, these sections are added as **strictly optional** tabs for owners who want deeper HR tracking.*

- **Section 4: Personal & Health Info (Optional)**
    - Family details / Emergency Contact Name and Phone Number.
    - Personal Health notes (e.g., known allergies or chronic conditions in case of a factory floor emergency).
- **Section 5: Address Details (Optional)**
    - Current Residence Address.
    - Permanent Village/Hometown Address.

### 2. Additions to Tab 5: Settings & Policies

*Expanded configurations to handle complex factory hierarchies and time-off rules.*

- **Leave Policy Configurator:**
    - Define the annual quota for Paid Leaves (e.g., 12 days/year) and Unpaid Leaves.
- **Reporting Manager Assignment:**
    - Ability to map specific workers to specific Supervisors, ensuring that a Supervisor's "Staff List" only shows the people on their specific factory line, rather than the entire company.

## Part 6: Open-Source Stack & UI/UX Guidelines (99% OSS)

*To achieve a best-in-class, premium, and highly professional application while maintaining near-zero licensing costs, the platform relies strictly on top-tier open-source technologies.*

### 1. Design Philosophy (Minimalism & Speed)

- **Monochrome + Accent Paradigm:** The app completely avoids heavy gradients and "playful" colors. The primary palette consists of clean whites, subtle grays, and deep blacks. Colors are used *exclusively* for data communication: 🟢 Green for Jama (Advance), 🔴 Red for Udhaar/Payables, and 🟡 Yellow for Half-Days.
- **Typography:** Utilizes **"Inter"** (via Google Fonts), the industry standard for enterprise SaaS. It ensures numbers, ledger entries, and vernacular scripts (Gujarati/Hindi) remain highly legible on low-resolution factory devices.
- **Enterprise Iconography:** Replacing default Android icons with **Phosphor Icons** or **Lucide Icons** (open-source libraries) to give the application a distinct, polished, and modern "Silicon Valley" SaaS feel.

### 2. Flutter Open-Source Arsenal (Frontend)

- **State & Routing:** `flutter_riverpod` (predictable state) and `go_router` (declarative routing).
- **Local Offline Storage:** `isar` database. Extremely high-speed NoSQL database built for Flutter, acting as the offline staging ground for attendance and ledger entries.
- **Background Sync:** `workmanager`. An open-source headless worker that reliably flushes offline data to the Go backend when the device detects a stable connection.
- **Data Visualization:** `fl_chart`. Used in the Admin Reports Hub to render clean, minimalist wage trend graphs without heavy library bloat.
- **Attendance Grid:** `table_calendar`. Stripped of standard styling to provide a flat, rapid-tap roster interface.
- **PDF Engine:** `pdf` package. Generates pixel-perfect, Tally-compatible Salary Slips locally or server-side.

### 3. Golang Minimalist Backend (API)

- **Routing Framework:** `go-chi/chi`. Chosen over heavier frameworks for its pure, minimalist approach to HTTP routing. It is lightweight, extremely fast, and adheres perfectly to standard Go practices.
- **Type-Safe Database Interfacing:** `sqlc`. We avoid bloated ORMs. `sqlc` generates highly optimized, type-safe Go code directly from raw PostgreSQL queries, ensuring maximum performance for bulk-attendance inserts.
- **Schema Migrations:** `pressly/goose`. A reliable, open-source tool to manage PostgreSQL database changes securely as the SaaS scales.

### 4. Zero Vendor Lock-in Infrastructure

- **Hosting:** Self-hosted via **Docker** containers on a **Hetzner VPS** (Linux).
- **Database:** **PostgreSQL** (100% open source). Utilizes native Row-Level Security (RLS) to ensure tenant data isolation without requiring expensive enterprise database management software.

## Part 7: Test-Driven Development (TDD) & DevOps Stack (100% OSS)

*To ensure absolute financial accuracy in payroll and ledger calculations, the platform adheres to a strict Test-Driven Development (TDD) lifecycle, utilizing industry-standard open-source tooling.*

### 1. Golang Backend TDD Stack

- **Test Runner & Assertions:** Standard `go test` paired with `stretchr/testify` for clean, readable assertions and require statements.
- **Mocking Framework:** `uber-go/mock` (GoMock). Used to auto-generate mock implementations of the `sqlc` Repository layer, allowing the Business/Service layer to be tested in complete isolation.
- **Integration Testing:** `testcontainers-go`. Before deploying, integration tests automatically spin up ephemeral PostgreSQL Docker containers, run the actual `sqlc` queries against the test database, and destroy the container, guaranteeing no SQL syntax errors leak to production.

### 2. Flutter Frontend TDD Stack

- **Dependency Mocking:** `mocktail`. Chosen specifically because it does not require running `build_runner` code generation, keeping the red-green-refactor TDD cycle instantaneous.
- **State Management Testing:** Native `Riverpod` Provider overrides. Allows the UI tests to inject mocked API responses without changing the widget tree.
- **Visual Regression Testing:** `golden_toolkit`. Used to take pixel-perfect snapshot tests of the "Red/Green" Staff Directory and Roster UI, ensuring the minimalistic design remains structurally intact across updates.

### 3. CI/CD & Observability (Zero-Cost DevOps)

- **Continuous Integration:** GitHub Actions. A workflow is configured to trigger on every Pull Request, running both the Flutter `flutter test` and Golang `go test ./...` suites. A merge is blocked unless all tests pass.
- **High-Performance Logging:** `rs/zerolog`. Implemented in the Go backend to provide structured, zero-allocation JSON logging. Essential for auditing background `workmanager` syncs from the offline Flutter app.

## Part 8: Specific UI Implementation & Advanced Page Layouts

### 1. Security & Access Control (New Required Flow) (Totally Optional, infact no need for this)

*Because factory tablets/phones are often shared or left on desks, the app requires a localized security layer to protect financial data.*

- **Page: App PIN / Biometric Lock Screen**
    - **UI:** Minimalist number pad.
    - **Logic:** Triggered every time the app is brought back from the background (after 2 minutes of inactivity). Uses the device's native fingerprint scanner (via `local_auth` package) or a fallback 4-digit PIN stored securely in Flutter's `flutter_secure_storage`.

### 2. Page Detail: The KYC Document Vault (Optimized)

- **Location:** Inside the Add/Edit Employee Form.
- **UI Layout:** Three flat, rectangular cards designated for "Aadhaar", "PAN", and "Bank Passbook".
- **Interaction:** Tapping a card opens the native camera.
- **Offline Implementation:** The captured image is immediately processed via `flutter_image_compress` to reduce size below 200KB, converted to Base64 or saved to local app directories, and linked to the Isar database. The UI displays a thumbnail.
- **Sync Logic:** Image binaries are synced to the Hetzner server in a separate background queue from standard text data to prevent blocking critical attendance syncs.

### 3. Page Detail: Bulk Attendance Mode (The Grid)

*While the standard list view is great, large factories (100+ workers) need a "Bulk Select" option to save time.*

- **Location:** A toggle switch on the Top Bar of the Daily Roster Tab ("List View" vs. "Bulk Mode").
- **UI:** A dense grid of employee avatars and names.
- **Interaction:**
    1. Supervisor taps `[ Select All ]`.
    2. Supervisor visually scans the floor and taps only the avatars of the 5 people who are absent. (Tapped avatars turn red).
    3. Supervisor taps `[ Mark Remaining as Present ]`.
    4. *Result:* 95 people marked Present, 5 marked Absent, in under 10 seconds.

### 4. Page Detail: The Advance (Udhaar) Approval Queue

*Since V1 includes the Employee Read-Only App with a "Request Advance" button, the Supervisor needs a place to manage these requests.*

- **Location:** A floating notification bell icon on the primary Dashboard.
- **UI:** A clean list of pending requests.
    - *Card Data:* Employee Name, Requested Amount, Current Outstanding Balance (crucial for decision making).
- **Action Row:** `[ Deny ]` or `[ Approve ]`.
- **Logic:** Tapping "Approve" automatically opens the "New Ledger Entry" modal, pre-filled with the requested amount and the employee's name, requiring just one final confirmation tap to write the transaction to the database.

## PAGES

Employee:

- wage_type: "monthly" | "daily" | "hourly" | "piece_rate"
- wage_amount: decimal
- default_shift_id: FK -> Shift
- piece_rate_item (optional): name + rate per unit

Shift (configurable, factory-level, multiple shifts allowed):

- name: "General", "Shift A", "Night Shift" etc.
- start_time: 09:30
- end_time: 20:30 (your example: 9:30 to 8:30, i.e. 11-hour shift)
- grace_period_minutes: late arrival tolerance
- is_default: bool

AttendanceRecord (one per employee per date):

- date
- shift_id (defaults to employee's default_shift, supervisor can override per-day)
- status: Present | Absent | Half-Day | Paid-Leave | Week-Off
- check_in_time (auto-filled = shift.start_time on tap; editable)
- check_out_time (auto-filled = shift.end_time on tap; editable)
- overtime_hours: decimal (manual entry or auto-calc if check_out > shift end)
- overtime_rate_multiplier: 1x/1.5x/2x (from policy, per-record override allowed)
- units_produced (only if wage_type = piece_rate)
- is_locked: bool (true after payroll generation)
- edited_by, edited_at (audit)

LedgerEntry:

- employee_id, date, type: Jama | Udhaar, amount, note, created_by
