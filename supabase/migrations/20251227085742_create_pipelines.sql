-- Create pipelines table
CREATE TABLE rastreia_lead_kiro_pipelines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_org_pipeline_name UNIQUE (organization_id, name)
);

-- Create pipeline_stages table
CREATE TABLE rastreia_lead_kiro_pipeline_stages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pipeline_id UUID NOT NULL REFERENCES rastreia_lead_kiro_pipelines(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color TEXT NOT NULL DEFAULT '#6B7280',
    probability INTEGER CHECK (probability >= 0 AND probability <= 100),
    sla_hours INTEGER CHECK (sla_hours > 0),
    position INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_pipeline_stage_name UNIQUE (pipeline_id, name),
    CONSTRAINT unique_pipeline_stage_position UNIQUE (pipeline_id, position)
);

-- Create indexes for pipelines
CREATE INDEX idx_pipelines_organization_id ON rastreia_lead_kiro_pipelines(organization_id);
CREATE INDEX idx_pipelines_is_default ON rastreia_lead_kiro_pipelines(organization_id, is_default) WHERE is_default = true;

-- Create indexes for pipeline_stages
CREATE INDEX idx_pipeline_stages_pipeline_id ON rastreia_lead_kiro_pipeline_stages(pipeline_id);
CREATE INDEX idx_pipeline_stages_position ON rastreia_lead_kiro_pipeline_stages(pipeline_id, position);

-- Enable RLS on pipelines
ALTER TABLE rastreia_lead_kiro_pipelines ENABLE ROW LEVEL SECURITY;

-- Enable RLS on pipeline_stages
ALTER TABLE rastreia_lead_kiro_pipeline_stages ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only access pipelines from their organization
CREATE POLICY pipelines_organization_isolation ON rastreia_lead_kiro_pipelines
    FOR ALL
    USING (
        organization_id IN (
            SELECT organization_id 
            FROM rastreia_lead_kiro_users 
            WHERE id = auth.uid()
        )
    );

-- RLS Policy: Users can only access pipeline stages from their organization's pipelines
CREATE POLICY pipeline_stages_organization_isolation ON rastreia_lead_kiro_pipeline_stages
    FOR ALL
    USING (
        pipeline_id IN (
            SELECT p.id 
            FROM rastreia_lead_kiro_pipelines p
            INNER JOIN rastreia_lead_kiro_users u ON u.organization_id = p.organization_id
            WHERE u.id = auth.uid()
        )
    );

-- Create trigger function for updated_at on pipelines
CREATE OR REPLACE FUNCTION update_pipelines_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for pipelines
CREATE TRIGGER trigger_update_pipelines_updated_at
    BEFORE UPDATE ON rastreia_lead_kiro_pipelines
    FOR EACH ROW
    EXECUTE FUNCTION update_pipelines_updated_at();

-- Create trigger function for updated_at on pipeline_stages
CREATE OR REPLACE FUNCTION update_pipeline_stages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for pipeline_stages
CREATE TRIGGER trigger_update_pipeline_stages_updated_at
    BEFORE UPDATE ON rastreia_lead_kiro_pipeline_stages
    FOR EACH ROW
    EXECUTE FUNCTION update_pipeline_stages_updated_at();

-- Function to ensure only one default pipeline per organization
CREATE OR REPLACE FUNCTION ensure_single_default_pipeline()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = true THEN
        -- Set all other pipelines in the organization to non-default
        UPDATE rastreia_lead_kiro_pipelines
        SET is_default = false
        WHERE organization_id = NEW.organization_id
          AND id != NEW.id
          AND is_default = true;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to ensure single default pipeline
CREATE TRIGGER trigger_ensure_single_default_pipeline
    BEFORE INSERT OR UPDATE ON rastreia_lead_kiro_pipelines
    FOR EACH ROW
    WHEN (NEW.is_default = true)
    EXECUTE FUNCTION ensure_single_default_pipeline();;
