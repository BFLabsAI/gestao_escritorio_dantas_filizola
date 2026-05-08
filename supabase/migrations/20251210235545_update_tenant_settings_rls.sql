
DROP POLICY IF EXISTS tenant_settings_audita_lead_select ON tenant_settings_audita_lead;
DROP POLICY IF EXISTS tenant_settings_audita_lead_insert ON tenant_settings_audita_lead;
DROP POLICY IF EXISTS tenant_settings_audita_lead_update ON tenant_settings_audita_lead;
DROP POLICY IF EXISTS tenant_settings_audita_lead_delete ON tenant_settings_audita_lead;

CREATE POLICY tenant_settings_audita_lead_select ON tenant_settings_audita_lead
FOR SELECT
USING (
  (tenant_id IN (
    SELECT ut.tenant_id 
    FROM user_tenants_audita_lead ut
    JOIN users_audita_lead u ON u.id = ut.user_id
    WHERE u.auth_user_id = auth.uid()
  )) 
  OR 
  is_superadmin_audita_lead()
);

CREATE POLICY tenant_settings_audita_lead_insert ON tenant_settings_audita_lead
FOR INSERT
WITH CHECK (
  (tenant_id IN (
    SELECT ut.tenant_id 
    FROM user_tenants_audita_lead ut
    JOIN users_audita_lead u ON u.id = ut.user_id
    WHERE u.auth_user_id = auth.uid()
  )) 
  OR 
  is_superadmin_audita_lead()
);

CREATE POLICY tenant_settings_audita_lead_update ON tenant_settings_audita_lead
FOR UPDATE
USING (
  (tenant_id IN (
    SELECT ut.tenant_id 
    FROM user_tenants_audita_lead ut
    JOIN users_audita_lead u ON u.id = ut.user_id
    WHERE u.auth_user_id = auth.uid()
  )) 
  OR 
  is_superadmin_audita_lead()
);

CREATE POLICY tenant_settings_audita_lead_delete ON tenant_settings_audita_lead
FOR DELETE
USING (
  is_superadmin_audita_lead()
);
;
