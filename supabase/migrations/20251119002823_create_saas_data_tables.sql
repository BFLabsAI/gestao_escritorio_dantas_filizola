-- 1. SAAS MESSAGE LOGS (Replaces disparador_r7_treinamentos)
CREATE TABLE IF NOT EXISTS saas_message_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES saas_tenants(id) ON DELETE CASCADE,
  instance_name TEXT,
  phone_number TEXT,
  message_content TEXT,
  status TEXT DEFAULT 'sent', -- sent, failed, pending
  campaign_name TEXT,
  campaign_type TEXT, -- 'manual', 'scheduled', 'copy_agent'
  error_message TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. SAAS SCHEDULES (Replaces agendamentos_...)
CREATE TABLE IF NOT EXISTS saas_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES saas_tenants(id) ON DELETE CASCADE,
  campaign_name TEXT NOT NULL,
  scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT DEFAULT 'pending', -- pending, processing, completed, failed
  contacts_json JSONB DEFAULT '[]',
  message_template JSONB DEFAULT '{}',
  instance_names TEXT[], -- Array of instances to use
  created_by UUID REFERENCES auth.users(id),
  execution_log TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. SAAS CHAT SESSIONS (Replaces copy_agent_...)
CREATE TABLE IF NOT EXISTS saas_chat_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES saas_tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  session_name TEXT,
  template_used TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS saas_chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID REFERENCES saas_chat_sessions(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. SAAS COMPANY SETTINGS (Replaces custom_prompt_...)
CREATE TABLE IF NOT EXISTS saas_company_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES saas_tenants(id) ON DELETE CASCADE UNIQUE,
  company_name TEXT,
  market_segment TEXT,
  company_size TEXT,
  brand_voice TEXT,
  brand_personality TEXT,
  main_products TEXT,
  target_audience TEXT,
  whatsapp_guidelines JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE saas_message_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE saas_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE saas_chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE saas_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE saas_company_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies (Generic Tenant Isolation)

-- Message Logs
CREATE POLICY "Tenant isolation for message logs" ON saas_message_logs FOR ALL USING (
  tenant_id IN (SELECT tenant_id FROM saas_users WHERE id = auth.uid())
);

-- Schedules
CREATE POLICY "Tenant isolation for schedules" ON saas_schedules FOR ALL USING (
  tenant_id IN (SELECT tenant_id FROM saas_users WHERE id = auth.uid())
);

-- Chat Sessions
CREATE POLICY "Tenant isolation for chat sessions" ON saas_chat_sessions FOR ALL USING (
  tenant_id IN (SELECT tenant_id FROM saas_users WHERE id = auth.uid())
);

-- Chat Messages (via session -> tenant)
CREATE POLICY "Tenant isolation for chat messages" ON saas_chat_messages FOR ALL USING (
  session_id IN (
    SELECT id FROM saas_chat_sessions 
    WHERE tenant_id IN (SELECT tenant_id FROM saas_users WHERE id = auth.uid())
  )
);

-- Company Settings
CREATE POLICY "Tenant isolation for settings" ON saas_company_settings FOR ALL USING (
  tenant_id IN (SELECT tenant_id FROM saas_users WHERE id = auth.uid())
);
;
