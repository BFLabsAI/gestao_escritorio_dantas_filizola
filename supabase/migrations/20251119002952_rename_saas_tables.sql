-- Rename Core Tables
ALTER TABLE IF EXISTS saas_plans RENAME TO plans_dispara_lead_saas;
ALTER TABLE IF EXISTS saas_tenants RENAME TO tenants_dispara_lead_saas;
ALTER TABLE IF EXISTS saas_users RENAME TO users_dispara_lead_saas;
ALTER TABLE IF EXISTS saas_instances RENAME TO instances_dispara_lead_saas;

-- Rename Data Tables
ALTER TABLE IF EXISTS saas_message_logs RENAME TO message_logs_dispara_lead_saas;
ALTER TABLE IF EXISTS saas_schedules RENAME TO schedules_dispara_lead_saas;
ALTER TABLE IF EXISTS saas_chat_sessions RENAME TO chat_sessions_dispara_lead_saas;
ALTER TABLE IF EXISTS saas_chat_messages RENAME TO chat_messages_dispara_lead_saas;
ALTER TABLE IF EXISTS saas_company_settings RENAME TO company_settings_dispara_lead_saas;

-- Update Foreign Key Constraints (Optional but good for clarity, though Postgres handles renaming usually)
-- We will just rely on Postgres to handle the underlying constraint renames or leave them as is since they work by OID.

-- Re-apply RLS Policies (Policies might need adjustment if they reference table names explicitly in strings, but usually they are attached to the table OID. However, the policy DEFINITIONS using subqueries might need updates if they used string references, but here they used SQL identifiers which Postgres updates automatically. Let's verify by re-asserting policies if needed, but usually renaming table is enough.)

-- Let's just ensure the policies are correct by dropping and recreating them to be safe and use the new names in definitions for future readability.

-- Plans
DROP POLICY IF EXISTS "Plans are viewable by everyone" ON plans_dispara_lead_saas;
CREATE POLICY "Plans are viewable by everyone" ON plans_dispara_lead_saas FOR SELECT USING (true);

-- Tenants
DROP POLICY IF EXISTS "Users can view own tenant" ON tenants_dispara_lead_saas;
CREATE POLICY "Users can view own tenant" ON tenants_dispara_lead_saas FOR SELECT USING (
  id IN (SELECT tenant_id FROM users_dispara_lead_saas WHERE id = auth.uid())
);

-- Users
DROP POLICY IF EXISTS "Users can view tenant members" ON users_dispara_lead_saas;
CREATE POLICY "Users can view tenant members" ON users_dispara_lead_saas FOR SELECT USING (
  tenant_id IN (SELECT tenant_id FROM users_dispara_lead_saas WHERE id = auth.uid())
);

-- Instances
DROP POLICY IF EXISTS "Users can view own instances" ON instances_dispara_lead_saas;
DROP POLICY IF EXISTS "Users can insert own instances" ON instances_dispara_lead_saas;
DROP POLICY IF EXISTS "Users can update own instances" ON instances_dispara_lead_saas;
DROP POLICY IF EXISTS "Users can delete own instances" ON instances_dispara_lead_saas;

CREATE POLICY "Users can view own instances" ON instances_dispara_lead_saas FOR SELECT USING (
  tenant_id IN (SELECT tenant_id FROM users_dispara_lead_saas WHERE id = auth.uid())
);
CREATE POLICY "Users can insert own instances" ON instances_dispara_lead_saas FOR INSERT WITH CHECK (
  tenant_id IN (SELECT tenant_id FROM users_dispara_lead_saas WHERE id = auth.uid())
);
CREATE POLICY "Users can update own instances" ON instances_dispara_lead_saas FOR UPDATE USING (
  tenant_id IN (SELECT tenant_id FROM users_dispara_lead_saas WHERE id = auth.uid())
);
CREATE POLICY "Users can delete own instances" ON instances_dispara_lead_saas FOR DELETE USING (
  tenant_id IN (SELECT tenant_id FROM users_dispara_lead_saas WHERE id = auth.uid())
);

-- Message Logs
DROP POLICY IF EXISTS "Tenant isolation for message logs" ON message_logs_dispara_lead_saas;
CREATE POLICY "Tenant isolation for message logs" ON message_logs_dispara_lead_saas FOR ALL USING (
  tenant_id IN (SELECT tenant_id FROM users_dispara_lead_saas WHERE id = auth.uid())
);

-- Schedules
DROP POLICY IF EXISTS "Tenant isolation for schedules" ON schedules_dispara_lead_saas;
CREATE POLICY "Tenant isolation for schedules" ON schedules_dispara_lead_saas FOR ALL USING (
  tenant_id IN (SELECT tenant_id FROM users_dispara_lead_saas WHERE id = auth.uid())
);

-- Chat Sessions
DROP POLICY IF EXISTS "Tenant isolation for chat sessions" ON chat_sessions_dispara_lead_saas;
CREATE POLICY "Tenant isolation for chat sessions" ON chat_sessions_dispara_lead_saas FOR ALL USING (
  tenant_id IN (SELECT tenant_id FROM users_dispara_lead_saas WHERE id = auth.uid())
);

-- Chat Messages
DROP POLICY IF EXISTS "Tenant isolation for chat messages" ON chat_messages_dispara_lead_saas;
CREATE POLICY "Tenant isolation for chat messages" ON chat_messages_dispara_lead_saas FOR ALL USING (
  session_id IN (
    SELECT id FROM chat_sessions_dispara_lead_saas 
    WHERE tenant_id IN (SELECT tenant_id FROM users_dispara_lead_saas WHERE id = auth.uid())
  )
);

-- Company Settings
DROP POLICY IF EXISTS "Tenant isolation for settings" ON company_settings_dispara_lead_saas;
CREATE POLICY "Tenant isolation for settings" ON company_settings_dispara_lead_saas FOR ALL USING (
  tenant_id IN (SELECT tenant_id FROM users_dispara_lead_saas WHERE id = auth.uid())
);;
