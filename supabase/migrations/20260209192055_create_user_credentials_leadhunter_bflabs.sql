-- Create user_credentials_leadhunter_bflabs table
CREATE TABLE IF NOT EXISTS public.user_credentials_leadhunter_bflabs (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    user_email VARCHAR(255),
    service_name VARCHAR(100),
    credential_type VARCHAR(50),
    credential_value TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    last_used TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_credentials_leadhunter_bflabs_user_email ON public.user_credentials_leadhunter_bflabs(user_email);
CREATE INDEX IF NOT EXISTS idx_user_credentials_leadhunter_bflabs_service_name ON public.user_credentials_leadhunter_bflabs(service_name);

COMMENT ON TABLE public.user_credentials_leadhunter_bflabs IS 'Stores API keys and credentials per user';;
