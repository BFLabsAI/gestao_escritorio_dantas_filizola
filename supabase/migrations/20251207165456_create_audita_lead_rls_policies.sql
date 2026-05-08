-- Audita Lead RLS Policies
-- Multi-tenant data isolation via Row Level Security

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================
ALTER TABLE tenants_audita_lead ENABLE ROW LEVEL SECURITY;
ALTER TABLE users_audita_lead ENABLE ROW LEVEL SECURITY;
ALTER TABLE instances_audita_lead ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts_audita_lead ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages_audita_lead ENABLE ROW LEVEL SECURITY;
ALTER TABLE exceptions_audita_lead ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads_audita_lead ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_settings_audita_lead ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get current user's tenant_id
CREATE OR REPLACE FUNCTION get_user_tenant_id_audita_lead()
RETURNS UUID AS $$
  SELECT tenant_id FROM users_audita_lead 
  WHERE auth_user_id = auth.uid()
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Check if current user is superadmin
CREATE OR REPLACE FUNCTION is_superadmin_audita_lead()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM users_audita_lead 
    WHERE auth_user_id = auth.uid() AND role = 'superadmin'
  )
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- ============================================
-- TENANTS TABLE POLICIES
-- ============================================
CREATE POLICY "tenants_audita_lead_select" ON tenants_audita_lead
  FOR SELECT USING (
    id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "tenants_audita_lead_insert" ON tenants_audita_lead
  FOR INSERT WITH CHECK (is_superadmin_audita_lead());

CREATE POLICY "tenants_audita_lead_update" ON tenants_audita_lead
  FOR UPDATE USING (is_superadmin_audita_lead());

CREATE POLICY "tenants_audita_lead_delete" ON tenants_audita_lead
  FOR DELETE USING (is_superadmin_audita_lead());

-- ============================================
-- USERS TABLE POLICIES
-- ============================================
CREATE POLICY "users_audita_lead_select" ON users_audita_lead
  FOR SELECT USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "users_audita_lead_insert" ON users_audita_lead
  FOR INSERT WITH CHECK (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "users_audita_lead_update" ON users_audita_lead
  FOR UPDATE USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "users_audita_lead_delete" ON users_audita_lead
  FOR DELETE USING (is_superadmin_audita_lead());

-- ============================================
-- INSTANCES TABLE POLICIES
-- ============================================
CREATE POLICY "instances_audita_lead_select" ON instances_audita_lead
  FOR SELECT USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "instances_audita_lead_insert" ON instances_audita_lead
  FOR INSERT WITH CHECK (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "instances_audita_lead_update" ON instances_audita_lead
  FOR UPDATE USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "instances_audita_lead_delete" ON instances_audita_lead
  FOR DELETE USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

-- ============================================
-- CONTACTS TABLE POLICIES
-- ============================================
CREATE POLICY "contacts_audita_lead_select" ON contacts_audita_lead
  FOR SELECT USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "contacts_audita_lead_insert" ON contacts_audita_lead
  FOR INSERT WITH CHECK (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "contacts_audita_lead_update" ON contacts_audita_lead
  FOR UPDATE USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "contacts_audita_lead_delete" ON contacts_audita_lead
  FOR DELETE USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

-- ============================================
-- MESSAGES TABLE POLICIES
-- ============================================
CREATE POLICY "messages_audita_lead_select" ON messages_audita_lead
  FOR SELECT USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "messages_audita_lead_insert" ON messages_audita_lead
  FOR INSERT WITH CHECK (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "messages_audita_lead_update" ON messages_audita_lead
  FOR UPDATE USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "messages_audita_lead_delete" ON messages_audita_lead
  FOR DELETE USING (is_superadmin_audita_lead());

-- ============================================
-- EXCEPTIONS TABLE POLICIES
-- ============================================
CREATE POLICY "exceptions_audita_lead_select" ON exceptions_audita_lead
  FOR SELECT USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "exceptions_audita_lead_insert" ON exceptions_audita_lead
  FOR INSERT WITH CHECK (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "exceptions_audita_lead_update" ON exceptions_audita_lead
  FOR UPDATE USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "exceptions_audita_lead_delete" ON exceptions_audita_lead
  FOR DELETE USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

-- ============================================
-- LEADS TABLE POLICIES (Public for landing page)
-- ============================================
CREATE POLICY "leads_audita_lead_select" ON leads_audita_lead
  FOR SELECT USING (is_superadmin_audita_lead());

-- Allow anonymous insert for lead capture form
CREATE POLICY "leads_audita_lead_insert" ON leads_audita_lead
  FOR INSERT WITH CHECK (true);

CREATE POLICY "leads_audita_lead_update" ON leads_audita_lead
  FOR UPDATE USING (is_superadmin_audita_lead());

CREATE POLICY "leads_audita_lead_delete" ON leads_audita_lead
  FOR DELETE USING (is_superadmin_audita_lead());

-- ============================================
-- TENANT SETTINGS TABLE POLICIES
-- ============================================
CREATE POLICY "tenant_settings_audita_lead_select" ON tenant_settings_audita_lead
  FOR SELECT USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "tenant_settings_audita_lead_insert" ON tenant_settings_audita_lead
  FOR INSERT WITH CHECK (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "tenant_settings_audita_lead_update" ON tenant_settings_audita_lead
  FOR UPDATE USING (
    tenant_id = get_user_tenant_id_audita_lead() OR is_superadmin_audita_lead()
  );

CREATE POLICY "tenant_settings_audita_lead_delete" ON tenant_settings_audita_lead
  FOR DELETE USING (is_superadmin_audita_lead());;
