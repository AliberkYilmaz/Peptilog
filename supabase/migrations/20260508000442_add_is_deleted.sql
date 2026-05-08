-- Add is_deleted column for soft-delete pattern (PEP-83)
-- Tables: peptides, injection_logs, weight_entries (matches Isar schema)

ALTER TABLE peptides         ADD COLUMN IF NOT EXISTS is_deleted boolean NOT NULL DEFAULT false;
ALTER TABLE injection_logs   ADD COLUMN IF NOT EXISTS is_deleted boolean NOT NULL DEFAULT false;
ALTER TABLE weight_entries   ADD COLUMN IF NOT EXISTS is_deleted boolean NOT NULL DEFAULT false;

-- Optional: index so list queries that filter is_deleted=false stay fast
CREATE INDEX IF NOT EXISTS idx_peptides_is_deleted        ON peptides(is_deleted)        WHERE is_deleted = false;
CREATE INDEX IF NOT EXISTS idx_injection_logs_is_deleted  ON injection_logs(is_deleted)  WHERE is_deleted = false;
CREATE INDEX IF NOT EXISTS idx_weight_entries_is_deleted  ON weight_entries(is_deleted)  WHERE is_deleted = false;
