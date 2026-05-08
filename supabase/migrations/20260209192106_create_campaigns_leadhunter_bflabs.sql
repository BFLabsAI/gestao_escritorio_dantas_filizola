-- Create campaigns_leadhunter_bflabs table
CREATE TABLE IF NOT EXISTS public.campaigns_leadhunter_bflabs (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    campaign_name VARCHAR(255),
    list_id BIGINT,
    status VARCHAR(50) DEFAULT 'draft',
    total_leads INTEGER DEFAULT 0,
    sent_count INTEGER DEFAULT 0,
    delivered_count INTEGER DEFAULT 0,
    response_count INTEGER DEFAULT 0,
    start_date DATE,
    end_date DATE
);

CREATE INDEX IF NOT EXISTS idx_campaigns_leadhunter_bflabs_status ON public.campaigns_leadhunter_bflabs(status);
CREATE INDEX IF NOT EXISTS idx_campaigns_leadhunter_bflabs_list_id ON public.campaigns_leadhunter_bflabs(list_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_leadhunter_bflabs_created_at ON public.campaigns_leadhunter_bflabs(created_at DESC);

COMMENT ON TABLE public.campaigns_leadhunter_bflabs IS 'Stores marketing campaigns';;
