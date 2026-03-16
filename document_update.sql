ALTER TABLE documents ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'pending';
ALTER TABLE documents ADD COLUMN IF NOT EXISTS verified_by TEXT;
