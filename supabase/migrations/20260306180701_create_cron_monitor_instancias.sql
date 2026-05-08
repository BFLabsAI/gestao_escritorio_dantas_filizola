
-- Habilitar extensão pg_cron se não estiver habilitada
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Deletar cron existente se houver
SELECT cron.unschedule('monitor-instancias-cron') WHERE EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'monitor-instancias-cron'
);

-- Criar cron job para rodar todo dia às 8h da manhã (UTC = 11h Brasil)
-- A função vai chamar a Edge Function via pg_net
SELECT cron.schedule(
    'monitor-instancias-cron',
    '0 11 * * *', -- Todo dia às 11h UTC (8h Brasil)
    $$
    SELECT
      net.http_post(
        url := 'https://iixeygzkgfwetchjvpvo.supabase.co/functions/v1/monitor-instancias',
        headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlpeGV5Z3prZndldGNodnB2byIsInJvbGUiOiJzZXJ2aWNlX3JvbGUiLCJpYXQiOjE3Mzc2NTI0NTcsImV4cCI6MjA1MzIyODQ1N30.K0a3rqERjMqxQdZ_ZxqH0fFOK0Y5nVQNLqVqVqVqVqU"}'::jsonb,
        body := '{}'::jsonb
      );
    $$
);

-- Verificar se o cron foi criado
SELECT jobname, schedule FROM cron.job WHERE jobname = 'monitor-instancias-cron';
;
