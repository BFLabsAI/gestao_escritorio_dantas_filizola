-- Create saved_searches_leadhunter_bflabs table
CREATE TABLE IF NOT EXISTS public.saved_searches_leadhunter_bflabs (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    search_name VARCHAR(255),
    search_type VARCHAR(50),
    platform VARCHAR(50),
    search_query TEXT,
    filters JSONB DEFAULT '{}'::jsonb,
    usage_count INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_saved_searches_leadhunter_bflabs_search_type ON public.saved_searches_leadhunter_bflabs(search_type);
CREATE INDEX IF NOT EXISTS idx_saved_searches_leadhunter_bflabs_created_at ON public.saved_searches_leadhunter_bflabs(created_at DESC);

COMMENT ON TABLE public.saved_searches_leadhunter_bflabs IS 'Stores saved search queries';;
