-- Drop the existing role check constraint and add 'installer' to it
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

ALTER TABLE users ADD CONSTRAINT users_role_check
  CHECK (role IN ('admin', 'superadmin', 'staff', 'factory', 'installer'));
