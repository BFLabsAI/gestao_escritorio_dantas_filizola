-- Create rastreia_lead_kiro_custom_fields table
CREATE TABLE IF NOT EXISTS rastreia_lead_kiro_custom_fields (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('contact', 'company', 'deal')),
  name TEXT NOT NULL,
  field_type TEXT NOT NULL CHECK (field_type IN ('text', 'number', 'date', 'dropdown', 'checkbox', 'url')),
  options JSONB, -- For dropdown type, stores array of options
  required_for_stage_ids UUID[] DEFAULT '{}', -- Array of stage IDs where this field is required
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT unique_org_entity_field_name UNIQUE (organization_id, entity_type, name)
);

-- Create indexes for custom_fields
CREATE INDEX IF NOT EXISTS idx_rastreia_lead_kiro_custom_fields_org_id ON rastreia_lead_kiro_custom_fields(organization_id);
CREATE INDEX IF NOT EXISTS idx_rastreia_lead_kiro_custom_fields_entity_type ON rastreia_lead_kiro_custom_fields(organization_id, entity_type);
CREATE INDEX IF NOT EXISTS idx_rastreia_lead_kiro_custom_fields_is_active ON rastreia_lead_kiro_custom_fields(organization_id, is_active) WHERE is_active = true;

-- Enable Row Level Security
ALTER TABLE rastreia_lead_kiro_custom_fields ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Organization isolation
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'rastreia_lead_kiro_custom_fields' 
    AND policyname = 'rastreia_lead_kiro_custom_fields_org_isolation'
  ) THEN
    CREATE POLICY rastreia_lead_kiro_custom_fields_org_isolation
      ON rastreia_lead_kiro_custom_fields
      FOR ALL
      USING (
        organization_id IN (
          SELECT organization_id 
          FROM rastreia_lead_kiro_users 
          WHERE id = auth.uid()
        )
      );
  END IF;
END $$;

-- Trigger to update updated_at timestamp
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_rastreia_lead_kiro_custom_fields_updated_at'
  ) THEN
    CREATE TRIGGER update_rastreia_lead_kiro_custom_fields_updated_at
      BEFORE UPDATE ON rastreia_lead_kiro_custom_fields
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;;
