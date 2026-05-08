ALTER TABLE users_dispara_lead_saas ADD COLUMN IF NOT EXISTS is_super_admin BOOLEAN DEFAULT FALSE;

-- Create a policy for Super Admins to view ALL tenants
-- Note: This requires bypassing RLS or having a policy that says "IF is_super_admin THEN TRUE"
-- But RLS policies are per table.
-- We need to update policies on ALL tables to allow super admin access.
-- This is tedious. Alternatively, we can use a "service role" client for the admin dashboard, but that's risky in frontend.
-- Better approach: Add a policy to `tenants_dispara_lead_saas` and others.

-- Policy for tenants: Super admins can view all
CREATE POLICY "Super admins can view all tenants" ON tenants_dispara_lead_saas FOR SELECT USING (
  (SELECT is_super_admin FROM users_dispara_lead_saas WHERE id = auth.uid()) = TRUE
);

-- Policy for plans: Everyone can view (already exists)

-- Policy for users: Super admins can view all users
CREATE POLICY "Super admins can view all users" ON users_dispara_lead_saas FOR SELECT USING (
  (SELECT is_super_admin FROM users_dispara_lead_saas WHERE id = auth.uid()) = TRUE
);

-- Policy for instances: Super admins can view all
CREATE POLICY "Super admins can view all instances" ON instances_dispara_lead_saas FOR SELECT USING (
  (SELECT is_super_admin FROM users_dispara_lead_saas WHERE id = auth.uid()) = TRUE
);

-- We might need similar policies for data tables if the admin wants to see logs.
-- For now, let's focus on Tenant Management (Tenants, Users, Instances).
;
