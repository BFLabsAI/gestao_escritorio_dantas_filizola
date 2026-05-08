-- Create campaign_contacts_disparalead table
CREATE TABLE IF NOT EXISTS campaign_contacts_disparalead (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    campaign_id uuid NOT NULL REFERENCES campaigns_disparalead(id) ON DELETE CASCADE,
    phone text NOT NULL,
    name text,
    data jsonb,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'delivered', 'read')),
    created_at timestamp with time zone DEFAULT now()
);

-- Create campaign_sends_disparalead table
CREATE TABLE IF NOT EXISTS campaign_sends_disparalead (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    campaign_id uuid NOT NULL REFERENCES campaigns_disparalead(id) ON DELETE CASCADE,
    contact_id uuid REFERENCES campaign_contacts_disparalead(id) ON DELETE CASCADE,
    phone text NOT NULL,
    status text DEFAULT 'queued' CHECK (status IN ('queued', 'sent', 'failed', 'delivered', 'read')),
    sent_at timestamp with time zone,
    failed_at timestamp with time zone,
    error_message text,
    provider_message_id text,
    created_at timestamp with time zone DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_campaign_contacts_campaign_id ON campaign_contacts_disparalead(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_sends_campaign_id ON campaign_sends_disparalead(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_sends_status ON campaign_sends_disparalead(status);

-- Enable RLS
ALTER TABLE campaign_contacts_disparalead ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_sends_disparalead ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can access their tenant's campaign contacts" ON campaign_contacts_disparalead
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM campaigns_disparalead c 
            WHERE c.id = campaign_contacts_disparalead.campaign_id 
            AND c.tenant_id IN (
                SELECT tenant_id FROM memberships_disparalead 
                WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can access their tenant's campaign sends" ON campaign_sends_disparalead
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM campaigns_disparalead c 
            WHERE c.id = campaign_sends_disparalead.campaign_id 
            AND c.tenant_id IN (
                SELECT tenant_id FROM memberships_disparalead 
                WHERE user_id = auth.uid()
            )
        )
    );;
