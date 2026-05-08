
-- 1. Create user_tenants_audita_lead
CREATE TABLE IF NOT EXISTS user_tenants_audita_lead (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  tenant_id UUID REFERENCES tenants_audita_lead(id) ON DELETE CASCADE NOT NULL,
  role TEXT CHECK (role IN ('admin', 'member')) DEFAULT 'member',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, tenant_id)
);

-- 2. Enable RLS on user_tenants_audita_lead
ALTER TABLE user_tenants_audita_lead ENABLE ROW LEVEL SECURITY;

-- 3. Policy for user_tenants_audita_lead
DROP POLICY IF EXISTS "Users can view their own tenant memberships" ON user_tenants_audita_lead;
CREATE POLICY "Users can view their own tenant memberships"
ON user_tenants_audita_lead
FOR SELECT
USING (auth.uid() = user_id);

-- 4. Create "Execut Compant" Tenant
INSERT INTO tenants_audita_lead (name, slug, instance_limit, user_limit)
VALUES ('Execut Compant', 'execut-compant', 5, 10)
ON CONFLICT (slug) DO NOTHING;

-- 5. Re-enable RLS on other tables
ALTER TABLE instances_audita_lead ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts_audita_lead ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenants_audita_lead ENABLE ROW LEVEL SECURITY;
ALTER TABLE users_audita_lead ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_settings_audita_lead ENABLE ROW LEVEL SECURITY;
ALTER TABLE exceptions_audita_lead ENABLE ROW LEVEL SECURITY;
-- Try enabling RLS on messages and leads if they exist
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'messages_audita_lead') THEN
        ALTER TABLE messages_audita_lead ENABLE ROW LEVEL SECURITY;
    END IF;
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'leads_audita_lead') THEN
        ALTER TABLE leads_audita_lead ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- 6. Update Policies for tenants_audita_lead
DROP POLICY IF EXISTS "Users can view tenants they belong to" ON tenants_audita_lead;
CREATE POLICY "Users can view tenants they belong to"
ON tenants_audita_lead
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM user_tenants_audita_lead
    WHERE user_tenants_audita_lead.tenant_id = tenants_audita_lead.id
    AND user_tenants_audita_lead.user_id = auth.uid()
  )
);
;
