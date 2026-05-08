-- Configure cron jobs for dispara_lead_production system

-- 1. Message queue worker - runs every 30 seconds
SELECT cron.schedule(
  'dispara_lead_production_message_worker',
  '*/30 * * * * *',
  $$
  SELECT net.http_post(
    url := SUPABASE_URL() || '/functions/v1/dispara-lead-production-queue-worker',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer " || SUPABASE_SERVICE_ROLE_KEY()}'::jsonb,
    body := '{"worker_type": "messages", "max_messages": 10}'::jsonb
  );
  $$
);

-- 2. Campaign queue worker - runs every 60 seconds
SELECT cron.schedule(
  'dispara_lead_production_campaign_worker',
  '*/60 * * * * *',
  $$
  SELECT net.http_post(
    url := SUPABASE_URL() || '/functions/v1/dispara-lead-production-queue-worker',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer " || SUPABASE_SERVICE_ROLE_KEY()}'::jsonb,
    body := '{"worker_type": "campaigns", "max_campaigns": 5}'::jsonb
  );
  $$
);

-- 3. Retry handler - runs every 5 minutes
SELECT cron.schedule(
  'dispara_lead_production_retry_handler',
  '*/5 * * * *',
  $$
  SELECT net.http_post(
    url := SUPABASE_URL() || '/functions/v1/dispara-lead-production-retry-handler',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer " || SUPABASE_SERVICE_ROLE_KEY()}'::jsonb,
    body := '{"process_messages": true, "process_campaigns": true}'::jsonb
  );
  $$
);

-- 4. Campaign scheduler - runs every minute for scheduled campaigns
SELECT cron.schedule(
  'dispara_lead_production_campaign_scheduler',
  '* * * * *',
  $$
  SELECT net.http_post(
    url := SUPABASE_URL() || '/functions/v1/dispara-lead-production-campaign-scheduler',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer " || SUPABASE_SERVICE_ROLE_KEY()}'::jsonb,
    body := '{"check_scheduled": true}'::jsonb
  );
  $$
);

-- 5. Stats updater - runs every 10 minutes
SELECT cron.schedule(
  'dispara_lead_production_stats_updater',
  '*/10 * * * *',
  $$
  SELECT net.http_post(
    url := SUPABASE_URL() || '/functions/v1/dispara-lead-production-dashboard-api',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer " || SUPABASE_SERVICE_ROLE_KEY()}'::jsonb,
    body := '{"action": "update_stats"}'::jsonb
  );
  $$
);

-- 6. Cleanup old messages - runs daily at 2 AM
SELECT cron.schedule(
  'dispara_lead_production_cleanup',
  '0 2 * * *',
  $$
  SELECT net.http_post(
    url := SUPABASE_URL() || '/functions/v1/dispara-lead-production-retry-handler',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer " || SUPABASE_SERVICE_ROLE_KEY()}'::jsonb,
    body := '{"action": "cleanup_old_messages"}'::jsonb
  );
  $$
);

-- 7. Health check - runs every 5 minutes
SELECT cron.schedule(
  'dispara_lead_production_health_check',
  '*/5 * * * *',
  $$
  SELECT net.http_post(
    url := SUPABASE_URL() || '/functions/v1/dispara-lead-production-dashboard-api',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer " || SUPABASE_SERVICE_ROLE_KEY()}'::jsonb,
    body := '{"action": "health_check"}'::jsonb
  );
  $$
);

-- Create table to track cron job execution
CREATE TABLE IF NOT EXISTS dispara_lead_production_cron_logs (
  id SERIAL PRIMARY KEY,
  job_name TEXT NOT NULL,
  status TEXT NOT NULL,
  response TEXT,
  error_message TEXT,
  executed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Grant permissions for cron logs table
GRANT SELECT, INSERT ON dispara_lead_production_cron_logs TO authenticated, anon;;
