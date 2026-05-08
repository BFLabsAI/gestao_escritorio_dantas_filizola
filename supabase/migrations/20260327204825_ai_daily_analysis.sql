create extension if not exists pgcrypto with schema extensions;
create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema extensions;

alter table public.n8n_chat_histories_web_sbot
    add column if not exists created_at timestamptz;

update public.n8n_chat_histories_web_sbot
set created_at = now()
where created_at is null;

alter table public.n8n_chat_histories_web_sbot
    alter column created_at set default now();

create index if not exists idx_n8n_chat_histories_web_sbot_created_at
    on public.n8n_chat_histories_web_sbot (created_at desc);

create index if not exists idx_n8n_chat_histories_web_sbot_session_id
    on public.n8n_chat_histories_web_sbot (session_id);

create table if not exists public.ai_analysis_users_itarget (
    id uuid primary key default gen_random_uuid(),
    analysis_date date not null unique,
    total_conversations integer not null default 0,
    inscricao_count integer not null default 0,
    recibos_documentos_count integer not null default 0,
    cancelamento_count integer not null default 0,
    duvidas_gerais_count integer not null default 0,
    category_counts jsonb not null default '{}'::jsonb,
    model text not null,
    processed_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.ai_analysis_web_rag_sbot (
    id uuid primary key default gen_random_uuid(),
    analysis_date date not null unique,
    total_conversations integer not null default 0,
    eventos_count integer not null default 0,
    duvidas_count integer not null default 0,
    institucional_count integer not null default 0,
    administrativo_financeiro_count integer not null default 0,
    category_counts jsonb not null default '{}'::jsonb,
    model text not null,
    processed_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

grant select on public.ai_analysis_users_itarget to anon, authenticated;
grant select on public.ai_analysis_web_rag_sbot to anon, authenticated;

do $$
declare
    users_job_id bigint;
    web_job_id bigint;
begin
    select jobid into users_job_id
    from cron.job
    where jobname = 'analyze-users-itarget-daily';

    if users_job_id is not null then
        perform cron.unschedule(users_job_id);
    end if;

    select jobid into web_job_id
    from cron.job
    where jobname = 'analyze-web-rag-sbot-daily';

    if web_job_id is not null then
        perform cron.unschedule(web_job_id);
    end if;
end $$;

select cron.schedule(
    'analyze-users-itarget-daily',
    '10 3 * * *',
    $$
    select
        net.http_post(
            url := 'https://iixeygzkgfwetchjvpvo.supabase.co/functions/v1/analyze-users-itarget',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlpeGV5Z3prZ2Z3ZXRjaGp2cHZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2MDc5NjMsImV4cCI6MjA3MTE4Mzk2M30.gWKk7Q1L_9Ci4j1AF05Di_ST6ZMF2F5l6zvoyKh_VMc',
                'apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlpeGV5Z3prZ2Z3ZXRjaGp2cHZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2MDc5NjMsImV4cCI6MjA3MTE4Mzk2M30.gWKk7Q1L_9Ci4j1AF05Di_ST6ZMF2F5l6zvoyKh_VMc'
            ),
            body := jsonb_build_object(
                'timezone', 'America/Fortaleza'
            )
        );
    $$
);

select cron.schedule(
    'analyze-web-rag-sbot-daily',
    '20 3 * * *',
    $$
    select
        net.http_post(
            url := 'https://iixeygzkgfwetchjvpvo.supabase.co/functions/v1/analyze-web-rag-sbot',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlpeGV5Z3prZ2Z3ZXRjaGp2cHZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2MDc5NjMsImV4cCI6MjA3MTE4Mzk2M30.gWKk7Q1L_9Ci4j1AF05Di_ST6ZMF2F5l6zvoyKh_VMc',
                'apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlpeGV5Z3prZ2Z3ZXRjaGp2cHZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2MDc5NjMsImV4cCI6MjA3MTE4Mzk2M30.gWKk7Q1L_9Ci4j1AF05Di_ST6ZMF2F5l6zvoyKh_VMc'
            ),
            body := jsonb_build_object(
                'timezone', 'America/Fortaleza'
            )
        );
    $$
);;
