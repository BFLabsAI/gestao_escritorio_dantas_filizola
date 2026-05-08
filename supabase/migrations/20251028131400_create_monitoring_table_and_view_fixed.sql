-- Create monitoring table for dispara_lead_production queue statistics
CREATE TABLE IF NOT EXISTS dispara_lead_production_queue_stats (
    id BIGSERIAL PRIMARY KEY,
    queue_name TEXT NOT NULL,
    pending_messages INTEGER DEFAULT 0,
    active_messages INTEGER DEFAULT 0,
    completed_messages INTEGER DEFAULT 0,
    failed_messages INTEGER DEFAULT 0,
    archived_messages INTEGER DEFAULT 0,
    total_processed INTEGER DEFAULT 0,
    avg_processing_time_seconds DECIMAL(10,2) DEFAULT 0,
    oldest_message_age_minutes INTEGER DEFAULT 0,
    messages_per_minute DECIMAL(8,2) DEFAULT 0,
    error_rate_percentage DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create queue monitoring view with correct column names
CREATE OR REPLACE VIEW dispara_lead_production_queue_monitor AS
SELECT
    'dispara_lead_production_message_queue' as queue_name,
    COUNT(*) as pending_count,
    MIN(enqueued_at) as oldest_message,
    MAX(enqueued_at) as newest_message,
    AVG(CASE WHEN vt > enqueued_at THEN EXTRACT(EPOCH FROM (vt - enqueued_at)) ELSE 0 END) as avg_visibility_timeout
FROM pgmq.q_dispara_lead_production_message_queue
UNION ALL
SELECT
    'dispara_lead_production_campaign_queue' as queue_name,
    COUNT(*) as pending_count,
    MIN(enqueued_at) as oldest_message,
    MAX(enqueued_at) as newest_message,
    AVG(CASE WHEN vt > enqueued_at THEN EXTRACT(EPOCH FROM (vt - enqueued_at)) ELSE 0 END) as avg_visibility_timeout
FROM pgmq.q_dispara_lead_production_campaign_queue;;
