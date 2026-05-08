-- Fix RLS policies for user registration flow
-- This allows authenticated users to create their first organization and user record

-- Organizations: Allow authenticated users to create organizations
CREATE POLICY "rastreia_lead_kiro_organizations_insert_authenticated"
ON rastreia_lead_kiro_organizations
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Organizations: Allow users to read their own organization
CREATE POLICY "rastreia_lead_kiro_organizations_select_own"
ON rastreia_lead_kiro_organizations
FOR SELECT
TO authenticated
USING (
  id IN (
    SELECT organization_id FROM rastreia_lead_kiro_users WHERE id = auth.uid()
  )
);

-- Organizations: Allow super_admin to update their organization
CREATE POLICY "rastreia_lead_kiro_organizations_update_super_admin"
ON rastreia_lead_kiro_organizations
FOR UPDATE
TO authenticated
USING (
  id IN (
    SELECT organization_id FROM rastreia_lead_kiro_users 
    WHERE id = auth.uid() AND role = 'super_admin'
  )
)
WITH CHECK (
  id IN (
    SELECT organization_id FROM rastreia_lead_kiro_users 
    WHERE id = auth.uid() AND role = 'super_admin'
  )
);

-- Users: Allow authenticated users to insert their own user record (for registration)
CREATE POLICY "rastreia_lead_kiro_users_insert_self"
ON rastreia_lead_kiro_users
FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());
;
