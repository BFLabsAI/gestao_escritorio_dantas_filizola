CREATE TABLE IF NOT EXISTS api_logs_itarget (
    id BIGSERIAL PRIMARY KEY,
    endpoint TEXT NOT NULL,
    method TEXT NOT NULL,
    request_body JSONB,
    response_body JSONB,
    status_code INTEGER,
    duration_ms INTEGER,
    error_message TEXT,
    user_id TEXT,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_logs_endpoint ON api_logs_itarget(endpoint);
CREATE INDEX IF NOT EXISTS idx_logs_status ON api_logs_itarget(status_code);
CREATE INDEX IF NOT EXISTS idx_logs_created ON api_logs_itarget(created_at DESC);

-- Enable Row Level Security
ALTER TABLE api_logs_itarget ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "allow_anon_logs" ON api_logs_itarget FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "service_full_logs" ON api_logs_itarget FOR ALL TO service_role USING (true) WITH CHECK (true);;
