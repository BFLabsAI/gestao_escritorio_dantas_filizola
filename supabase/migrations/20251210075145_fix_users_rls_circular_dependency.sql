-- Fix circular dependency in users_audita_lead RLS policy
-- Users should always be able to read their own record by auth_user_id

DROP POLICY IF EXISTS users_audita_lead_select ON users_audita_lead;

CREATE POLICY users_audita_lead_select ON users_audita_lead
  FOR SELECT
  USING (
    auth_user_id = auth.uid()  -- Can always read own record
    OR tenant_id = get_user_tenant_id_audita_lead()  -- Can read same tenant
    OR is_superadmin_audita_lead()  -- Superadmin can read all
  );;
