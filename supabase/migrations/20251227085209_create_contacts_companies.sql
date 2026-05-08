-- Create rastreia_lead_kiro_companies table
CREATE TABLE rastreia_lead_kiro_companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    cnpj TEXT,
    website TEXT,
    industry TEXT,
    custom_fields JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create rastreia_lead_kiro_contacts table
CREATE TABLE rastreia_lead_kiro_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
    email TEXT,
    phone TEXT,
    full_name TEXT NOT NULL,
    cpf TEXT,
    company_id UUID REFERENCES rastreia_lead_kiro_companies(id) ON DELETE SET NULL,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    source TEXT,
    owner_id UUID REFERENCES rastreia_lead_kiro_users(id) ON DELETE SET NULL,
    custom_fields JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create indexes for better query performance
CREATE INDEX idx_rastreia_lead_kiro_companies_org_id ON rastreia_lead_kiro_companies(organization_id);
CREATE INDEX idx_rastreia_lead_kiro_companies_cnpj ON rastreia_lead_kiro_companies(cnpj) WHERE cnpj IS NOT NULL;

CREATE INDEX idx_rastreia_lead_kiro_contacts_org_id ON rastreia_lead_kiro_contacts(organization_id);
CREATE INDEX idx_rastreia_lead_kiro_contacts_email ON rastreia_lead_kiro_contacts(email) WHERE email IS NOT NULL;
CREATE INDEX idx_rastreia_lead_kiro_contacts_phone ON rastreia_lead_kiro_contacts(phone) WHERE phone IS NOT NULL;
CREATE INDEX idx_rastreia_lead_kiro_contacts_cpf ON rastreia_lead_kiro_contacts(cpf) WHERE cpf IS NOT NULL;
CREATE INDEX idx_rastreia_lead_kiro_contacts_company_id ON rastreia_lead_kiro_contacts(company_id) WHERE company_id IS NOT NULL;
CREATE INDEX idx_rastreia_lead_kiro_contacts_owner_id ON rastreia_lead_kiro_contacts(owner_id) WHERE owner_id IS NOT NULL;
CREATE INDEX idx_rastreia_lead_kiro_contacts_tags ON rastreia_lead_kiro_contacts USING GIN(tags);

-- Enable Row Level Security
ALTER TABLE rastreia_lead_kiro_companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE rastreia_lead_kiro_contacts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for rastreia_lead_kiro_companies
-- Organization isolation policy
CREATE POLICY "rastreia_lead_kiro_companies_org_isolation"
ON rastreia_lead_kiro_companies
FOR ALL
USING (
    organization_id IN (
        SELECT organization_id 
        FROM rastreia_lead_kiro_users 
        WHERE id = auth.uid()
    )
);

-- RLS Policies for rastreia_lead_kiro_contacts
-- Organization isolation with role-based access
CREATE POLICY "rastreia_lead_kiro_contacts_org_isolation"
ON rastreia_lead_kiro_contacts
FOR SELECT
USING (
    organization_id IN (
        SELECT organization_id 
        FROM rastreia_lead_kiro_users 
        WHERE id = auth.uid()
    )
    AND (
        -- Super Admin and Manager can see all contacts
        (SELECT role FROM rastreia_lead_kiro_users WHERE id = auth.uid()) IN ('super_admin', 'manager')
        -- Consultant can only see their assigned contacts
        OR owner_id = auth.uid()
    )
);

-- Insert/Update/Delete policies for contacts (all roles can modify within their scope)
CREATE POLICY "rastreia_lead_kiro_contacts_insert"
ON rastreia_lead_kiro_contacts
FOR INSERT
WITH CHECK (
    organization_id IN (
        SELECT organization_id 
        FROM rastreia_lead_kiro_users 
        WHERE id = auth.uid()
    )
);

CREATE POLICY "rastreia_lead_kiro_contacts_update"
ON rastreia_lead_kiro_contacts
FOR UPDATE
USING (
    organization_id IN (
        SELECT organization_id 
        FROM rastreia_lead_kiro_users 
        WHERE id = auth.uid()
    )
    AND (
        (SELECT role FROM rastreia_lead_kiro_users WHERE id = auth.uid()) IN ('super_admin', 'manager')
        OR owner_id = auth.uid()
    )
);

CREATE POLICY "rastreia_lead_kiro_contacts_delete"
ON rastreia_lead_kiro_contacts
FOR DELETE
USING (
    organization_id IN (
        SELECT organization_id 
        FROM rastreia_lead_kiro_users 
        WHERE id = auth.uid()
    )
    AND (SELECT role FROM rastreia_lead_kiro_users WHERE id = auth.uid()) IN ('super_admin', 'manager')
);

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers to automatically update updated_at
CREATE TRIGGER update_rastreia_lead_kiro_companies_updated_at
    BEFORE UPDATE ON rastreia_lead_kiro_companies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rastreia_lead_kiro_contacts_updated_at
    BEFORE UPDATE ON rastreia_lead_kiro_contacts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();;
