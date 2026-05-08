-- Enable required extensions for dispara_lead_production
CREATE EXTENSION IF NOT EXISTS pgmq;
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Create PGMQ queues for dispara_lead_production
SELECT pgmq.create('dispara_lead_production_message_queue');
SELECT pgmq.create('dispara_lead_production_campaign_queue');

-- Add comments for documentation
COMMENT ON TABLE pgmq.q_dispara_lead_production_message_queue IS 'Queue for individual WhatsApp messages in dispara_lead_production';
COMMENT ON TABLE pgmq.q_dispara_lead_production_campaign_queue IS 'Queue for campaign processing in dispara_lead_production';;
