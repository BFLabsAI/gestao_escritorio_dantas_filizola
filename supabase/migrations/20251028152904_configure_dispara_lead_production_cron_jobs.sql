-- Configure cron jobs for dispara_lead_production automation system
-- Make sure pg_cron is enabled and create scheduled tasks

-- Message queue worker - runs every 30 seconds
SELECT cron.schedule(
  'dispara-lead-production-message-worker',
  '*/30 * * * *',
  $$
  SELECT net.http_post(
    url := SUPABASE_URL() || '/functions/v1/dispara-lead-production-queue-worker',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer " || SUPABASE_SERVICE_ROLE_KEY()}',
    body := '{"worker_type": "messages", "max_messages": 10}'
  );
  $$
);

-- Campaign queue worker - runs every 2 minutes
SELECT cron.schedule(
  'dispara-lead-production-campaign-worker',
  '*/2 * * * *',
  $$
  SELECT net.http_post(
    url := SUPABASE_URL() || '/functions/v1/dispara-lead-production-queue-worker',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer " || SUPABASE_SERVICE_ROLE_KEY()}',
    body := '{"worker_type": "campaigns", "max_campaigns": 5}'
  );
  $$
);

-- Retry handler - runs every 5 minutes
SELECT cron.schedule(
  'dispara-lead-production-retry-handler',
  '*/5 * * * *',
  $$
  SELECT net.http_post(
    url := SUPABASE_URL() || '/functions/v1/dispara-lead-production-retry-handler',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer " || SUPABASE_SERVICE_ROLE_KEY()}',
    body := '{}'
  );
  $$
);

-- Campaign scheduler - runs every minute for scheduled campaigns
SELECT cron.schedule(
  'dispara-lead-production-campaign-scheduler',
  '* * * * *',
  $$
  SELECT net.http_post(
    url := SUPABASE_URL() || '/functions/v1/dispara-lead-production-campaign-scheduler',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer " || SUPABASE_SERVICE_ROLE_KEY()}',
    body := '{}'
  );
  $$
);

-- Statistics updater - runs every 10 minutes
SELECT cron.schedule(
  'dispara-lead-production-stats-updater',
  '*/10 * * * *',
  $$
  UPDATE disparador_r7_treinamentos 
  SET queue_status = CASE 
    WHEN processed_messages = total_messages THEN 'completed'
    WHEN processed_messages > 0 THEN 'partial'
    ELSE 'pending'
  END
  WHERE total_messages > 0 
  AND queue_status IN ('pending', 'partial', 'processing');
  $$
);

-- Cleanup old logs - runs daily at 2 AM
SELECT cron.schedule(
  'dispara-lead-production-cleanup',
  '0 2 * * *',
  $$
  DELETE FROM disparador_r7_treinamentos 
  WHERE created_at < NOW() - INTERVAL '30 days'
  AND queue_status IN ('completed', 'failed');
  $$
);

-- Health check - runs every 15 minutes
SELECT cron.schedule(
  'dispara-lead-production-health-check',
  '*/15 * * * *',
  $$
  SELECT net.http_post(
    url := SUPABASE_URL() || '/functions/v1/dispara-lead-production-dashboard-api',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer " || SUPABASE_SERVICE_ROLE_KEY()}',
    body := '{"action": "health-check"}'
  );
  $$
);

-- Grant necessary permissions for cron jobs
GRANT USAGE ON SCHEMA cron TO authenticated, anon;;
