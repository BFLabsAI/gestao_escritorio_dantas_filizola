-- Allow Super Admins to update tenants
CREATE POLICY "Super admins can update tenants"
ON tenants_dispara_lead_saas
FOR UPDATE
TO authenticated
USING (
  is_super_admin()
);

-- Allow Super Admins to insert tenants
CREATE POLICY "Super admins can insert tenants"
ON tenants_dispara_lead_saas
FOR INSERT
TO authenticated
WITH CHECK (
  is_super_admin()
);

-- Allow Super Admins to update users (e.g. roles)
CREATE POLICY "Super admins can update users"
ON users_dispara_lead_saas
FOR UPDATE
TO authenticated
USING (
  is_super_admin()
);
;
