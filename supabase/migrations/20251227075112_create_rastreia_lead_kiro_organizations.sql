-- Create rastreia_lead_kiro_organizations table
CREATE TABLE rastreia_lead_kiro_organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  logo_url TEXT,
  address TEXT,
  tax_id TEXT,
  timezone TEXT NOT NULL DEFAULT 'America/Sao_Paulo',
  business_hours JSONB NOT NULL DEFAULT '{
    "monday": {"start": "09:00", "end": "18:00"},
    "tuesday": {"start": "09:00", "end": "18:00"},
    "wednesday": {"start": "09:00", "end": "18:00"},
    "thursday": {"start": "09:00", "end": "18:00"},
    "friday": {"start": "09:00", "end": "18:00"},
    "saturday": null,
    "sunday": null
  }'::jsonb,
  default_currency TEXT NOT NULL DEFAULT 'BRL',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE rastreia_lead_kiro_organizations ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION rastreia_lead_kiro_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for organizations
CREATE TRIGGER rastreia_lead_kiro_organizations_updated_at
  BEFORE UPDATE ON rastreia_lead_kiro_organizations
  FOR EACH ROW
  EXECUTE FUNCTION rastreia_lead_kiro_update_updated_at();

-- Add index
CREATE INDEX idx_rastreia_lead_kiro_organizations_name ON rastreia_lead_kiro_organizations(name);

-- Add comment
COMMENT ON TABLE rastreia_lead_kiro_organizations IS 'Multi-tenant organizations for LeadHub Workspace';;
