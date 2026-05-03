-- ============================================================
-- Installer Team Management — Supabase Migration
-- ============================================================

-- 1. Installer Teams table
CREATE TABLE IF NOT EXISTS installer_teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  phone TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE installer_teams ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read installer_teams
CREATE POLICY "Authenticated users can read installer_teams"
  ON installer_teams FOR SELECT
  TO authenticated
  USING (true);

-- Allow authenticated users to insert installer_teams
CREATE POLICY "Authenticated users can insert installer_teams"
  ON installer_teams FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow authenticated users to update installer_teams
CREATE POLICY "Authenticated users can update installer_teams"
  ON installer_teams FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Allow authenticated users to delete installer_teams
CREATE POLICY "Authenticated users can delete installer_teams"
  ON installer_teams FOR DELETE
  TO authenticated
  USING (true);

-- 2. Team Application Assignments table
CREATE TABLE IF NOT EXISTS team_application_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES installer_teams(id) ON DELETE CASCADE,
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  assigned_by UUID,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (team_id, application_id)
);

-- Enable RLS
ALTER TABLE team_application_assignments ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read team_application_assignments
CREATE POLICY "Authenticated users can read team_application_assignments"
  ON team_application_assignments FOR SELECT
  TO authenticated
  USING (true);

-- Allow authenticated users to insert team_application_assignments
CREATE POLICY "Authenticated users can insert team_application_assignments"
  ON team_application_assignments FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow authenticated users to update team_application_assignments
CREATE POLICY "Authenticated users can update team_application_assignments"
  ON team_application_assignments FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Allow authenticated users to delete team_application_assignments
CREATE POLICY "Authenticated users can delete team_application_assignments"
  ON team_application_assignments FOR DELETE
  TO authenticated
  USING (true);

-- 3. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_installer_teams_user_id ON installer_teams(user_id);
CREATE INDEX IF NOT EXISTS idx_installer_teams_email ON installer_teams(email);
CREATE INDEX IF NOT EXISTS idx_team_app_assignments_team_id ON team_application_assignments(team_id);
CREATE INDEX IF NOT EXISTS idx_team_app_assignments_app_id ON team_application_assignments(application_id);
