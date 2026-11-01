-- +goose Up

-- Allow disputes to reference an attendance record instead of a ledger entry
-- (employee "Report Error" on their attendance calendar).
ALTER TABLE ledger_disputes ADD COLUMN attendance_id UUID REFERENCES attendance(id) ON DELETE SET NULL;
ALTER TABLE ledger_disputes ALTER COLUMN ledger_id DROP NOT NULL;

CREATE INDEX idx_ledger_disputes_attendance ON ledger_disputes (attendance_id);

-- +goose Down
ALTER TABLE ledger_disputes DROP COLUMN IF EXISTS attendance_id;
ALTER TABLE ledger_disputes ALTER COLUMN ledger_id SET NOT NULL;