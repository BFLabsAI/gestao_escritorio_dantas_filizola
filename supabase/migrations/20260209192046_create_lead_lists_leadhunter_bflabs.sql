-- Create lead_lists_leadhunter_bflabs table
CREATE TABLE IF NOT EXISTS public.lead_lists_leadhunter_bflabs (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    list_name VARCHAR(255),
    search_type VARCHAR(50),
    platform VARCHAR(50),
    search_term TEXT,
    leads_data JSONB DEFAULT '[]'::jsonb,
    total_count INTEGER DEFAULT 0,
    whatsapp_count INTEGER DEFAULT 0,
    exported BOOLEAN DEFAULT FALSE,
    tags TEXT[] DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_lead_lists_leadhunter_bflabs_search_type ON public.lead_lists_leadhunter_bflabs(search_type);
CREATE INDEX IF NOT EXISTS idx_lead_lists_leadhunter_bflabs_created_at ON public.lead_lists_leadhunter_bflabs(created_at DESC);

COMMENT ON TABLE public.lead_lists_leadhunter_bflabs IS 'Stores lead lists from searches';;
