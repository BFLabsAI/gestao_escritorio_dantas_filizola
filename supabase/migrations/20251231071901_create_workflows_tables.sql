-- Create workflows and workflow_executions tables
-- Requirements: 16.1, 16.2, 16.3

-- Workflows table
CREATE TABLE IF NOT EXISTS rastreia_lead_kiro_workflows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT false,
  trigger JSONB NOT NULL DEFAULT '{}',
  actions JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Workflow executions table
CREATE TABLE IF NOT EXISTS rastreia_lead_kiro_workflow_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id UUID NOT NULL REFERENCES rastreia_lead_kiro_workflows(id) ON DELETE CASCADE,
  trigger_data JSONB NOT NULL DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed')),
  current_action_index INTEGER DEFAULT 0,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  error TEXT,
  retry_count INTEGER DEFAULT 0,
  next_retry_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_workflows_organization 
ON rastreia_lead_kiro_workflows(organization_id);

CREATE INDEX IF NOT EXISTS idx_workflows_active 
ON rastreia_lead_kiro_workflows(organization_id, is_active);

CREATE INDEX IF NOT EXISTS idx_workflow_executions_workflow 
ON rastreia_lead_kiro_workflow_executions(workflow_id);

CREATE INDEX IF NOT EXISTS idx_workflow_executions_status 
ON rastreia_lead_kiro_workflow_executions(status);

CREATE INDEX IF NOT EXISTS idx_workflow_executions_pending 
ON rastreia_lead_kiro_workflow_executions(status, next_retry_at) 
WHERE status IN ('pending', 'failed');

-- Enable RLS
ALTER TABLE rastreia_lead_kiro_workflows ENABLE ROW LEVEL SECURITY;
ALTER TABLE rastreia_lead_kiro_workflow_executions ENABLE ROW LEVEL SECURITY;

-- RLS policies for workflows
CREATE POLICY "rastreia_lead_kiro_workflows_org_isolation"
ON rastreia_lead_kiro_workflows
FOR ALL
USING (
  organization_id IN (
    SELECT organization_id FROM rastreia_lead_kiro_users WHERE id = auth.uid()
  )
);

-- RLS policies for workflow executions
CREATE POLICY "rastreia_lead_kiro_workflow_executions_org_isolation"
ON rastreia_lead_kiro_workflow_executions
FOR ALL
USING (
  workflow_id IN (
    SELECT w.id FROM rastreia_lead_kiro_workflows w
    JOIN rastreia_lead_kiro_users u ON w.organization_id = u.organization_id
    WHERE u.id = auth.uid()
  )
);

-- Trigger for updated_at on workflows
CREATE OR REPLACE FUNCTION update_workflows_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_workflows_updated_at
  BEFORE UPDATE ON rastreia_lead_kiro_workflows
  FOR EACH ROW
  EXECUTE FUNCTION update_workflows_updated_at();;
