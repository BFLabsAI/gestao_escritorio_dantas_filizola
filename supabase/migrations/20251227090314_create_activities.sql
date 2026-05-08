-- Create activities table for audit logging
CREATE TABLE rastreia_lead_kiro_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('call', 'message', 'note', 'stage_change', 'field_change', 'email', 'meeting')),
  contact_id UUID REFERENCES rastreia_lead_kiro_contacts(id) ON DELETE CASCADE,
  deal_id UUID REFERENCES rastreia_lead_kiro_deals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES rastreia_lead_kiro_users(id) ON DELETE RESTRICT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create indexes for common queries
CREATE INDEX idx_rastreia_lead_kiro_activities_org ON rastreia_lead_kiro_activities(organization_id);
CREATE INDEX idx_rastreia_lead_kiro_activities_contact ON rastreia_lead_kiro_activities(contact_id);
CREATE INDEX idx_rastreia_lead_kiro_activities_deal ON rastreia_lead_kiro_activities(deal_id);
CREATE INDEX idx_rastreia_lead_kiro_activities_user ON rastreia_lead_kiro_activities(user_id);
CREATE INDEX idx_rastreia_lead_kiro_activities_created_at ON rastreia_lead_kiro_activities(created_at DESC);
CREATE INDEX idx_rastreia_lead_kiro_activities_type ON rastreia_lead_kiro_activities(type);

-- Enable Row Level Security
ALTER TABLE rastreia_lead_kiro_activities ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Organization isolation
CREATE POLICY rastreia_lead_kiro_activities_org_isolation
ON rastreia_lead_kiro_activities
FOR ALL
USING (
  organization_id IN (
    SELECT organization_id 
    FROM rastreia_lead_kiro_users 
    WHERE id = auth.uid()
  )
);

-- RLS Policy: Consultants can only see activities for their contacts/deals
CREATE POLICY rastreia_lead_kiro_activities_consultant_access
ON rastreia_lead_kiro_activities
FOR SELECT
USING (
  organization_id IN (
    SELECT organization_id 
    FROM rastreia_lead_kiro_users 
    WHERE id = auth.uid()
  )
  AND (
    -- Managers and super_admins see all activities in their org
    (SELECT role FROM rastreia_lead_kiro_users WHERE id = auth.uid()) IN ('super_admin', 'manager')
    OR
    -- Consultants see activities for contacts they own
    (
      contact_id IN (
        SELECT id FROM rastreia_lead_kiro_contacts WHERE owner_id = auth.uid()
      )
    )
    OR
    -- Consultants see activities for deals they own
    (
      deal_id IN (
        SELECT id FROM rastreia_lead_kiro_deals WHERE owner_id = auth.uid()
      )
    )
    OR
    -- Users can see their own activities
    user_id = auth.uid()
  )
);

-- Database trigger function for automatic activity logging on deal changes
CREATE OR REPLACE FUNCTION rastreia_lead_kiro_log_deal_changes()
RETURNS TRIGGER AS $$
BEGIN
  -- Log stage changes
  IF (TG_OP = 'UPDATE' AND OLD.stage_id IS DISTINCT FROM NEW.stage_id) THEN
    INSERT INTO rastreia_lead_kiro_activities (
      organization_id,
      type,
      deal_id,
      contact_id,
      user_id,
      metadata
    ) VALUES (
      NEW.organization_id,
      'stage_change',
      NEW.id,
      NEW.contact_id,
      auth.uid(),
      jsonb_build_object(
        'old_stage_id', OLD.stage_id,
        'new_stage_id', NEW.stage_id,
        'timestamp', now()
      )
    );
  END IF;

  -- Log field changes (value, probability, expected_close_date, won status)
  IF (TG_OP = 'UPDATE' AND (
    OLD.value IS DISTINCT FROM NEW.value OR
    OLD.probability IS DISTINCT FROM NEW.probability OR
    OLD.expected_close_date IS DISTINCT FROM NEW.expected_close_date OR
    OLD.won IS DISTINCT FROM NEW.won
  )) THEN
    INSERT INTO rastreia_lead_kiro_activities (
      organization_id,
      type,
      deal_id,
      contact_id,
      user_id,
      metadata
    ) VALUES (
      NEW.organization_id,
      'field_change',
      NEW.id,
      NEW.contact_id,
      auth.uid(),
      jsonb_build_object(
        'changes', jsonb_build_object(
          'value', CASE WHEN OLD.value IS DISTINCT FROM NEW.value 
            THEN jsonb_build_object('old', OLD.value, 'new', NEW.value) 
            ELSE NULL END,
          'probability', CASE WHEN OLD.probability IS DISTINCT FROM NEW.probability 
            THEN jsonb_build_object('old', OLD.probability, 'new', NEW.probability) 
            ELSE NULL END,
          'expected_close_date', CASE WHEN OLD.expected_close_date IS DISTINCT FROM NEW.expected_close_date 
            THEN jsonb_build_object('old', OLD.expected_close_date, 'new', NEW.expected_close_date) 
            ELSE NULL END,
          'won', CASE WHEN OLD.won IS DISTINCT FROM NEW.won 
            THEN jsonb_build_object('old', OLD.won, 'new', NEW.won) 
            ELSE NULL END
        ),
        'timestamp', now()
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for deal changes
CREATE TRIGGER rastreia_lead_kiro_deal_changes_trigger
AFTER UPDATE ON rastreia_lead_kiro_deals
FOR EACH ROW
EXECUTE FUNCTION rastreia_lead_kiro_log_deal_changes();

-- Comment on table
COMMENT ON TABLE rastreia_lead_kiro_activities IS 'Activity log for audit trail and timeline display. Tracks all interactions and changes related to contacts and deals.';;
