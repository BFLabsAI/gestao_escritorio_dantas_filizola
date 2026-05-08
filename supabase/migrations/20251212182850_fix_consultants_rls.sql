DROP POLICY IF EXISTS "Enable delete access for users in same tenant" ON consultants_audita_lead;
DROP POLICY IF EXISTS "Enable insert access for users in same tenant" ON consultants_audita_lead;
DROP POLICY IF EXISTS "Enable read access for users in same tenant" ON consultants_audita_lead;
DROP POLICY IF EXISTS "Enable update access for users in same tenant" ON consultants_audita_lead;

CREATE POLICY "consultants_select_policy" ON consultants_audita_lead
FOR SELECT
USING (
  tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
);

CREATE POLICY "consultants_insert_policy" ON consultants_audita_lead
FOR INSERT
WITH CHECK (
  tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
);

CREATE POLICY "consultants_update_policy" ON consultants_audita_lead
FOR UPDATE
USING (
  tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
)
WITH CHECK (
  tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
);

CREATE POLICY "consultants_delete_policy" ON consultants_audita_lead
FOR DELETE
USING (
  tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
);;
