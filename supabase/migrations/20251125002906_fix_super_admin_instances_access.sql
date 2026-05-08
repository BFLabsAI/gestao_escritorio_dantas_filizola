-- Fix RLS for super admins to access any tenant's instances
-- Drop existing super admin view policy
DROP POLICY IF EXISTS "Super admins can view all instances" ON instances_dispara_lead_saas;

-- Recreate with better logic - super admins OR own tenant
CREATE POLICY "Users can view instances (super admin or own tenant)"
ON instances_dispara_lead_saas
FOR SELECT
USING (
  ( SELECT is_super_admin FROM users_dispara_lead_saas WHERE id = auth.uid() ) = true
  OR
  tenant_id IN ( SELECT tenant_id FROM users_dispara_lead_saas WHERE id = auth.uid() )
);;
