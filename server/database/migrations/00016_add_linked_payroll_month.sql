-- +goose Up
ALTER TABLE ledger ADD COLUMN linked_payroll_month text;

-- +goose Down
ALTER TABLE ledger DROP COLUMN IF EXISTS linked_payroll_month;
