-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. SAAS PLANS
CREATE TABLE IF NOT EXISTS saas_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  max_instances INTEGER DEFAULT 1,
  max_messages_month INTEGER DEFAULT 1000,
  price DECIMAL(10, 2) DEFAULT 0.00,
  features JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default plans
INSERT INTO saas_plans (name, slug, max_instances, max_messages_month, price)
VALUES 
('Basic', 'basic', 1, 1000, 0.00),
('Pro', 'pro', 5, 10000, 99.00),
('Enterprise', 'enterprise', 20, 100000, 299.00)
ON CONFLICT (slug) DO NOTHING;

-- 2. SAAS TENANTS (Companies)
CREATE TABLE IF NOT EXISTS saas_tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  plan_id UUID REFERENCES saas_plans(id),
  owner_id UUID REFERENCES auth.users(id),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'pending')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. SAAS USERS (Profiles linked to Auth)
CREATE TABLE IF NOT EXISTS saas_users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES saas_tenants(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
  full_name TEXT,
  email TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. SAAS INSTANCES (Evolution API Mapping)
CREATE TABLE IF NOT EXISTS saas_instances (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES saas_tenants(id) ON DELETE CASCADE,
  instance_name TEXT NOT NULL,
  instance_id TEXT, -- Evolution API ID if needed
  status TEXT DEFAULT 'disconnected',
  connection_status TEXT DEFAULT 'open',
  server_url TEXT, -- Optional: if we support multiple Evolution servers
  api_key TEXT,    -- Optional: if each instance has a different key
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(tenant_id, instance_name)
);

-- Enable RLS
ALTER TABLE saas_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE saas_tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE saas_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE saas_instances ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Plans: Readable by everyone (public info)
CREATE POLICY "Plans are viewable by everyone" ON saas_plans FOR SELECT USING (true);

-- Tenants: Users can view their own tenant
CREATE POLICY "Users can view own tenant" ON saas_tenants FOR SELECT USING (
  id IN (SELECT tenant_id FROM saas_users WHERE id = auth.uid())
);

-- Users: Users can view members of their own tenant
CREATE POLICY "Users can view tenant members" ON saas_users FOR SELECT USING (
  tenant_id IN (SELECT tenant_id FROM saas_users WHERE id = auth.uid())
);

-- Instances: Users can view/edit instances of their own tenant
CREATE POLICY "Users can view own instances" ON saas_instances FOR SELECT USING (
  tenant_id IN (SELECT tenant_id FROM saas_users WHERE id = auth.uid())
);
CREATE POLICY "Users can insert own instances" ON saas_instances FOR INSERT WITH CHECK (
  tenant_id IN (SELECT tenant_id FROM saas_users WHERE id = auth.uid())
);
CREATE POLICY "Users can update own instances" ON saas_instances FOR UPDATE USING (
  tenant_id IN (SELECT tenant_id FROM saas_users WHERE id = auth.uid())
);
CREATE POLICY "Users can delete own instances" ON saas_instances FOR DELETE USING (
  tenant_id IN (SELECT tenant_id FROM saas_users WHERE id = auth.uid())
);
;
