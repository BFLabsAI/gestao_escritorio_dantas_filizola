-- Create role enum type for users
CREATE TYPE rastreia_lead_kiro_user_role AS ENUM ('super_admin', 'manager', 'consultant');

-- Create teams table
CREATE TABLE rastreia_lead_kiro_teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create users table
CREATE TABLE rastreia_lead_kiro_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  role rastreia_lead_kiro_user_role NOT NULL DEFAULT 'consultant',
  team_id UUID REFERENCES rastreia_lead_kiro_teams(id) ON DELETE SET NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(organization_id, email)
);

-- Create indexes for better query performance
CREATE INDEX idx_rastreia_lead_kiro_users_organization_id ON rastreia_lead_kiro_users(organization_id);
CREATE INDEX idx_rastreia_lead_kiro_users_team_id ON rastreia_lead_kiro_users(team_id);
CREATE INDEX idx_rastreia_lead_kiro_users_email ON rastreia_lead_kiro_users(email);
CREATE INDEX idx_rastreia_lead_kiro_users_role ON rastreia_lead_kiro_users(role);
CREATE INDEX idx_rastreia_lead_kiro_teams_organization_id ON rastreia_lead_kiro_teams(organization_id);

-- Enable RLS on both tables
ALTER TABLE rastreia_lead_kiro_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE rastreia_lead_kiro_users ENABLE ROW LEVEL SECURITY;

-- RLS Policies for teams table
-- Organization isolation: users can only see teams in their organization
CREATE POLICY "rastreia_lead_kiro_teams_org_isolation"
ON rastreia_lead_kiro_teams
FOR ALL
USING (
  organization_id IN (
    SELECT organization_id FROM rastreia_lead_kiro_users WHERE id = auth.uid()
  )
);

-- RLS Policies for users table
-- Super Admin and Manager: can see all users in their organization
CREATE POLICY "rastreia_lead_kiro_users_manager_access"
ON rastreia_lead_kiro_users
FOR SELECT
USING (
  organization_id IN (
    SELECT u.organization_id 
    FROM rastreia_lead_kiro_users u 
    WHERE u.id = auth.uid() 
    AND u.role IN ('super_admin', 'manager')
  )
);

-- Consultant: can only see themselves
CREATE POLICY "rastreia_lead_kiro_users_consultant_self_access"
ON rastreia_lead_kiro_users
FOR SELECT
USING (
  id = auth.uid()
  AND (
    SELECT role FROM rastreia_lead_kiro_users WHERE id = auth.uid()
  ) = 'consultant'
);

-- Super Admin: can insert/update/delete users in their organization
CREATE POLICY "rastreia_lead_kiro_users_super_admin_write"
ON rastreia_lead_kiro_users
FOR ALL
USING (
  organization_id IN (
    SELECT u.organization_id 
    FROM rastreia_lead_kiro_users u 
    WHERE u.id = auth.uid() 
    AND u.role = 'super_admin'
  )
);

-- Users can update their own profile (limited fields handled at app level)
CREATE POLICY "rastreia_lead_kiro_users_self_update"
ON rastreia_lead_kiro_users
FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Create updated_at trigger function if not exists
CREATE OR REPLACE FUNCTION rastreia_lead_kiro_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
CREATE TRIGGER rastreia_lead_kiro_teams_updated_at
  BEFORE UPDATE ON rastreia_lead_kiro_teams
  FOR EACH ROW
  EXECUTE FUNCTION rastreia_lead_kiro_update_updated_at();

CREATE TRIGGER rastreia_lead_kiro_users_updated_at
  BEFORE UPDATE ON rastreia_lead_kiro_users
  FOR EACH ROW
  EXECUTE FUNCTION rastreia_lead_kiro_update_updated_at();

-- Add comments for documentation
COMMENT ON TABLE rastreia_lead_kiro_teams IS 'Teams for Round Robin lead distribution in LeadHub Workspace';
COMMENT ON TABLE rastreia_lead_kiro_users IS 'Users with role-based access control for LeadHub Workspace';
COMMENT ON COLUMN rastreia_lead_kiro_users.role IS 'User role: super_admin (full access), manager (org-wide access), consultant (own data only)';;
