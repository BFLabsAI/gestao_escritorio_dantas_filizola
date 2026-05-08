-- Enable pg_cron extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Set up campaign scheduler cron job (every 30 minutes)
-- This will check for campaigns scheduled within the next 30 minute window
SELECT cron.schedule(
  'campaign-scheduler-30min',
  '*/30 * * * *', -- Every 30 minutes
  $$
    SELECT net.http_post(
      url := 'https://yxcnzwjyomfocpegqtmr.supabase.co/functions/v1/pgmq-campaign-manager',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.settings.service_role_key') || '"}',
      body := '{"action": "check_scheduled"}'
    );
  $$
);

-- Set up message worker cron job (every 10 seconds)  
-- This will process one message at a time from the queue
SELECT cron.schedule(
  'campaign-worker-10sec',
  '*/10 * * * * *', -- Every 10 seconds (note the extra * for seconds)
  $$
    SELECT net.http_post(
      url := 'https://yxcnzwjyomfocpegqtmr.supabase.co/functions/v1/pgmq-campaign-manager',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.settings.service_role_key') || '"}',
      body := '{"action": "process_messages"}'
    );
  $$
);;
