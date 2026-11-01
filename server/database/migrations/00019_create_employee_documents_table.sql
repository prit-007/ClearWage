-- +goose Up
CREATE TABLE employee_documents (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    doc_type text NOT NULL CHECK (doc_type IN ('aadhaar', 'pan', 'bank')),
    file_path text NOT NULL,
    public_id text,
    original_name text,
    uploaded_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (employee_id, doc_type)
);

CREATE INDEX idx_employee_documents_tenant_employee ON employee_documents (tenant_id, employee_id);

-- +goose Down
DROP INDEX IF EXISTS idx_employee_documents_tenant_employee;
DROP TABLE IF EXISTS employee_documents;
