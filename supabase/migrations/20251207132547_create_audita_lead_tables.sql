-- Audita Lead Platform Tables
-- Multi-tenant SaaS for WhatsApp conversation auditing

-- ============================================
-- TENANTS TABLE
-- ============================================
CREATE TABLE tenants_audita_lead (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    instance_limit INTEGER DEFAULT 3,
    user_limit INTEGER DEFAULT 10,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users_audita_lead (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants_audita_lead(id) ON DELETE CASCADE,
    auth_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'consultant', -- 'admin', 'consultant', 'superadmin'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_users_audita_lead_tenant ON users_audita_lead(tenant_id);
CREATE INDEX idx_users_audita_lead_auth_user ON users_audita_lead(auth_user_id);
CREATE UNIQUE INDEX idx_users_audita_lead_auth_user_unique ON users_audita_lead(auth_user_id);

-- ============================================
-- INSTANCES TABLE (WhatsApp connections)
-- ============================================
CREATE TABLE instances_audita_lead (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants_audita_lead(id) ON DELETE CASCADE,
    uazapi_instance_id TEXT UNIQUE,
    name TEXT NOT NULL,
    phone_number TEXT,
    status TEXT DEFAULT 'disconnected', -- 'connected', 'disconnected', 'connecting'
    metadata JSONB DEFAULT '{}',
    last_connected_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_instances_audita_lead_tenant ON instances_audita_lead(tenant_id);
CREATE INDEX idx_instances_audita_lead_status ON instances_audita_lead(status);

-- ============================================
-- CONTACTS TABLE
-- ============================================
CREATE TABLE contacts_audita_lead (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants_audita_lead(id) ON DELETE CASCADE,
    phone TEXT NOT NULL,
    name TEXT,
    email TEXT,
    tags TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    first_message_at TIMESTAMPTZ,
    last_message_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, phone)
);

CREATE INDEX idx_contacts_audita_lead_tenant ON contacts_audita_lead(tenant_id);
CREATE INDEX idx_contacts_audita_lead_phone ON contacts_audita_lead(phone);
CREATE INDEX idx_contacts_audita_lead_tenant_phone ON contacts_audita_lead(tenant_id, phone);

-- ============================================
-- MESSAGES TABLE
-- ============================================
CREATE TABLE messages_audita_lead (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants_audita_lead(id) ON DELETE CASCADE,
    instance_id UUID NOT NULL REFERENCES instances_audita_lead(id) ON DELETE CASCADE,
    contact_id UUID NOT NULL REFERENCES contacts_audita_lead(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users_audita_lead(id) ON DELETE SET NULL,
    uazapi_message_id TEXT,
    direction TEXT NOT NULL, -- 'inbound', 'outbound'
    message_type TEXT NOT NULL DEFAULT 'text', -- 'text', 'image', 'audio', 'video', 'document', 'sticker'
    content TEXT,
    media_url TEXT,
    is_read BOOLEAN DEFAULT false,
    sent_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_messages_audita_lead_tenant ON messages_audita_lead(tenant_id);
CREATE INDEX idx_messages_audita_lead_tenant_contact ON messages_audita_lead(tenant_id, contact_id);
CREATE INDEX idx_messages_audita_lead_sent_at ON messages_audita_lead(sent_at);
CREATE INDEX idx_messages_audita_lead_instance ON messages_audita_lead(instance_id);
CREATE INDEX idx_messages_audita_lead_direction ON messages_audita_lead(direction);

-- ============================================
-- EXCEPTIONS TABLE (contacts excluded from metrics)
-- ============================================
CREATE TABLE exceptions_audita_lead (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants_audita_lead(id) ON DELETE CASCADE,
    phone TEXT NOT NULL,
    reason TEXT,
    added_by UUID REFERENCES users_audita_lead(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, phone)
);

CREATE INDEX idx_exceptions_audita_lead_tenant ON exceptions_audita_lead(tenant_id);
CREATE INDEX idx_exceptions_audita_lead_phone ON exceptions_audita_lead(phone);

-- ============================================
-- LEADS TABLE (landing page captures)
-- ============================================
CREATE TABLE leads_audita_lead (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    company_name TEXT NOT NULL,
    salespeople_count INTEGER NOT NULL,
    status TEXT DEFAULT 'new', -- 'new', 'contacted', 'qualified', 'converted'
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_leads_audita_lead_status ON leads_audita_lead(status);
CREATE INDEX idx_leads_audita_lead_created_at ON leads_audita_lead(created_at);

-- ============================================
-- TENANT SETTINGS TABLE
-- ============================================
CREATE TABLE tenant_settings_audita_lead (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID UNIQUE NOT NULL REFERENCES tenants_audita_lead(id) ON DELETE CASCADE,
    notifications_enabled BOOLEAN DEFAULT true,
    auto_reply_enabled BOOLEAN DEFAULT false,
    auto_reply_message TEXT,
    business_hours JSONB DEFAULT '{"start": "08:00", "end": "18:00", "days": [1,2,3,4,5]}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_audita_lead()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to all tables with updated_at column
CREATE TRIGGER trigger_tenants_audita_lead_updated_at
    BEFORE UPDATE ON tenants_audita_lead
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_audita_lead();

CREATE TRIGGER trigger_users_audita_lead_updated_at
    BEFORE UPDATE ON users_audita_lead
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_audita_lead();

CREATE TRIGGER trigger_instances_audita_lead_updated_at
    BEFORE UPDATE ON instances_audita_lead
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_audita_lead();

CREATE TRIGGER trigger_contacts_audita_lead_updated_at
    BEFORE UPDATE ON contacts_audita_lead
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_audita_lead();

CREATE TRIGGER trigger_tenant_settings_audita_lead_updated_at
    BEFORE UPDATE ON tenant_settings_audita_lead
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_audita_lead();;
