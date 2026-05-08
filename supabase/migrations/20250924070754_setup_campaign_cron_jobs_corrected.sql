-- Remove existing cron jobs if they exist
SELECT cron.unschedule('campaign-scheduler-30min');
SELECT cron.unschedule('campaign-worker-10sec');

-- Set up campaign scheduler cron job (every 30 minutes)
-- This will check for campaigns scheduled within the next 30 minute window
SELECT cron.schedule(
  'campaign-scheduler-30min',
  '*/30 * * * *', -- Every 30 minutes
  $$
    SELECT net.http_post(
      url := 'https://iixeygzkgfwetchjvpvo.supabase.co/functions/v1/pgmq-campaign-manager',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlpeGV5Z3prZ2Z3ZXRjaGp2cHZvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTYwNzk2MywiZXhwIjoyMDcxMTgzOTYzfQ.DIdkkX_pOUNtJhMu_xNxDZhZr9PjIjy0_m4wc4rPJm4"}',
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
      url := 'https://iixeygzkgfwetchjvpvo.supabase.co/functions/v1/pgmq-campaign-manager',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlpeGV5Z3prZ2Z3ZXRjaGp2cHZvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTYwNzk2MywiZXhwIjoyMDcxMTgzOTYzfQ.DIdkkX_pOUNtJhMu_xNxDZhZr9PjIjy0_m4wc4rPJm4"}',
      body := '{"action": "process_messages"}'
    );
  $$
);;
