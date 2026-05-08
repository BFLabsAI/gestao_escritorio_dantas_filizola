-- Create integrations table for ad platform connections
-- Requirements: 5.2, 5.3

CREATE TABLE IF NOT EXISTS rastreia_lead_kiro_integrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('whatsapp', 'meta_ads', 'google_ads', 'google_calendar', 'outlook')),
  name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'disconnected' CHECK (status IN ('connected', 'disconnected', 'error')),
  credentials JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for organization lookups
CREATE INDEX IF NOT EXISTS idx_integrations_organization 
ON rastreia_lead_kiro_integrations(organization_id);

-- Create index for type lookups
CREATE INDEX IF NOT EXISTS idx_integrations_type 
ON rastreia_lead_kiro_integrations(organization_id, type);

-- Enable RLS
ALTER TABLE rastreia_lead_kiro_integrations ENABLE ROW LEVEL SECURITY;

-- RLS policy for organization isolation
CREATE POLICY "rastreia_lead_kiro_integrations_org_isolation"
ON rastreia_lead_kiro_integrations
FOR ALL
USING (
  organization_id IN (
    SELECT organization_id FROM rastreia_lead_kiro_users WHERE id = auth.uid()
  )
);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_integrations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_integrations_updated_at
  BEFORE UPDATE ON rastreia_lead_kiro_integrations
  FOR EACH ROW
  EXECUTE FUNCTION update_integrations_updated_at();;
