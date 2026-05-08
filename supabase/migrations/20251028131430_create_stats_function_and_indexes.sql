-- Create queue statistics update function
CREATE OR REPLACE FUNCTION update_dispara_lead_production_queue_stats()
RETURNS void AS $$
BEGIN
    -- Update message queue statistics
    INSERT INTO dispara_lead_production_queue_stats (
        queue_name, pending_messages, updated_at
    )
    SELECT
        'dispara_lead_production_message_queue',
        COUNT(*),
        NOW()
    FROM pgmq.q_dispara_lead_production_message_queue
    ON CONFLICT (queue_name)
    DO UPDATE SET
        pending_messages = EXCLUDED.pending_messages,
        updated_at = NOW()
    WHERE dispara_lead_production_queue_stats.queue_name = 'dispara_lead_production_message_queue';

    -- Update campaign queue statistics
    INSERT INTO dispara_lead_production_queue_stats (
        queue_name, pending_messages, updated_at
    )
    SELECT
        'dispara_lead_production_campaign_queue',
        COUNT(*),
        NOW()
    FROM pgmq.q_dispara_lead_production_campaign_queue
    ON CONFLICT (queue_name)
    DO UPDATE SET
        pending_messages = EXCLUDED.pending_messages,
        updated_at = NOW()
    WHERE dispara_lead_production_queue_stats.queue_name = 'dispara_lead_production_campaign_queue';
END;
$$ LANGUAGE plpgsql;

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_disparador_queue_status ON disparador_r7_treinamentos(queue_status);
CREATE INDEX IF NOT EXISTS idx_disparador_next_retry_at ON disparador_r7_treinamentos(next_retry_at);
CREATE INDEX IF NOT EXISTS idx_disparador_queue_msg_id ON disparador_r7_treinamentos(queue_msg_id);
CREATE INDEX IF NOT EXISTS idx_agendamentos_queue_status ON agendamentos_disparador_r7_treinamentos(queue_status);
CREATE INDEX IF NOT EXISTS idx_agendamentos_queue_msg_id ON agendamentos_disparador_r7_treinamentos(queue_msg_id);
CREATE INDEX IF NOT EXISTS idx_queue_stats_queue_name_updated_at ON dispara_lead_production_queue_stats(queue_name, updated_at DESC);

-- Grant permissions
GRANT SELECT ON dispara_lead_production_queue_monitor TO authenticated;
GRANT SELECT ON dispara_lead_production_queue_monitor TO anon;
GRANT EXECUTE ON FUNCTION update_dispara_lead_production_queue_stats TO authenticated;
GRANT SELECT ON dispara_lead_production_queue_stats TO authenticated;
GRANT SELECT ON dispara_lead_production_queue_stats TO anon;;
