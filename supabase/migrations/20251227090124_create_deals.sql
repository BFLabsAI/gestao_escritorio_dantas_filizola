-- Create rastreia_lead_kiro_loss_reasons table
CREATE TABLE rastreia_lead_kiro_loss_reasons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(organization_id, name)
);

-- Create index on organization_id for loss_reasons
CREATE INDEX idx_rastreia_lead_kiro_loss_reasons_org_id ON rastreia_lead_kiro_loss_reasons(organization_id);

-- Create rastreia_lead_kiro_deals table
CREATE TABLE rastreia_lead_kiro_deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  value DECIMAL(15, 2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'BRL',
  pipeline_id UUID NOT NULL REFERENCES rastreia_lead_kiro_pipelines(id) ON DELETE RESTRICT,
  stage_id UUID NOT NULL REFERENCES rastreia_lead_kiro_pipeline_stages(id) ON DELETE RESTRICT,
  contact_id UUID NOT NULL REFERENCES rastreia_lead_kiro_contacts(id) ON DELETE CASCADE,
  company_id UUID REFERENCES rastreia_lead_kiro_companies(id) ON DELETE SET NULL,
  owner_id UUID NOT NULL REFERENCES rastreia_lead_kiro_users(id) ON DELETE RESTRICT,
  probability INTEGER NOT NULL DEFAULT 0 CHECK (probability >= 0 AND probability <= 100),
  expected_close_date DATE,
  closed_at TIMESTAMPTZ,
  won BOOLEAN,
  loss_reason_id UUID REFERENCES rastreia_lead_kiro_loss_reasons(id) ON DELETE SET NULL,
  products JSONB NOT NULL DEFAULT '[]'::jsonb,
  custom_fields JSONB NOT NULL DEFAULT '{}'::jsonb,
  stage_entered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Constraint: if deal is lost (won = false), loss_reason_id should be provided
  CONSTRAINT check_loss_reason CHECK (
    (won IS NULL) OR 
    (won = true) OR 
    (won = false AND loss_reason_id IS NOT NULL)
  )
);

-- Create indexes for deals table
CREATE INDEX idx_rastreia_lead_kiro_deals_org_id ON rastreia_lead_kiro_deals(organization_id);
CREATE INDEX idx_rastreia_lead_kiro_deals_pipeline_id ON rastreia_lead_kiro_deals(pipeline_id);
CREATE INDEX idx_rastreia_lead_kiro_deals_stage_id ON rastreia_lead_kiro_deals(stage_id);
CREATE INDEX idx_rastreia_lead_kiro_deals_contact_id ON rastreia_lead_kiro_deals(contact_id);
CREATE INDEX idx_rastreia_lead_kiro_deals_owner_id ON rastreia_lead_kiro_deals(owner_id);
CREATE INDEX idx_rastreia_lead_kiro_deals_company_id ON rastreia_lead_kiro_deals(company_id);
CREATE INDEX idx_rastreia_lead_kiro_deals_stage_entered_at ON rastreia_lead_kiro_deals(stage_entered_at);

-- Enable Row Level Security
ALTER TABLE rastreia_lead_kiro_loss_reasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE rastreia_lead_kiro_deals ENABLE ROW LEVEL SECURITY;

-- RLS Policies for loss_reasons
-- Organization isolation policy
CREATE POLICY rastreia_lead_kiro_loss_reasons_org_isolation
  ON rastreia_lead_kiro_loss_reasons
  FOR ALL
  USING (
    organization_id IN (
      SELECT organization_id 
      FROM rastreia_lead_kiro_users 
      WHERE id = auth.uid()
    )
  );

-- RLS Policies for deals
-- Organization isolation policy for managers and super_admins
CREATE POLICY rastreia_lead_kiro_deals_org_isolation
  ON rastreia_lead_kiro_deals
  FOR ALL
  USING (
    organization_id IN (
      SELECT organization_id 
      FROM rastreia_lead_kiro_users 
      WHERE id = auth.uid()
      AND role IN ('super_admin', 'manager')
    )
  );

-- Consultant access policy - only see deals they own
CREATE POLICY rastreia_lead_kiro_deals_consultant_access
  ON rastreia_lead_kiro_deals
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 
      FROM rastreia_lead_kiro_users 
      WHERE id = auth.uid()
      AND role = 'consultant'
      AND organization_id = rastreia_lead_kiro_deals.organization_id
      AND id = rastreia_lead_kiro_deals.owner_id
    )
  );

-- Trigger to update updated_at timestamp for loss_reasons
CREATE TRIGGER update_rastreia_lead_kiro_loss_reasons_updated_at
  BEFORE UPDATE ON rastreia_lead_kiro_loss_reasons
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update updated_at timestamp for deals
CREATE TRIGGER update_rastreia_lead_kiro_deals_updated_at
  BEFORE UPDATE ON rastreia_lead_kiro_deals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
;
