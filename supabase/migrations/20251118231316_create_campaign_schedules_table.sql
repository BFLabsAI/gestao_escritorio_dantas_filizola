create extension if not exists pg_cron;

create table if not exists campaign_schedules (
  id uuid primary key default gen_random_uuid(),
  campaign_name text not null,
  scheduled_at timestamptz not null,
  status text not null default 'pending' check (status in ('pending', 'processing', 'completed', 'failed')),
  payload jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  error_log text
);

create index if not exists idx_campaign_schedules_status_scheduled_at 
on campaign_schedules(status, scheduled_at);;
