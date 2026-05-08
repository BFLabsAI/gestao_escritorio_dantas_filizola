create table if not exists public.deal_events_falconcrm (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references public.deals_falconcrm(id) on delete cascade,
  user_id uuid not null references public.app_user_falconcrm(id) on delete cascade,
  event_type text not null,
  from_stage_id uuid null,
  to_stage_id uuid null,
  from_stage_name text null,
  to_stage_name text null,
  loss_reason_id uuid null references public.loss_reasons_falconcrm(id) on delete set null,
  amount_snapshot numeric null,
  probability_snapshot integer null,
  product_id_snapshot uuid null,
  metadata jsonb null default '{}'::jsonb,
  created_at timestamp with time zone not null default now()
);

create index if not exists idx_deal_events_falconcrm_deal_created_at
  on public.deal_events_falconcrm (deal_id, created_at desc);

create index if not exists idx_deal_events_falconcrm_user_created_at
  on public.deal_events_falconcrm (user_id, created_at desc);

create index if not exists idx_deal_events_falconcrm_type_created_at
  on public.deal_events_falconcrm (event_type, created_at desc);

create index if not exists idx_deal_events_falconcrm_to_stage_created_at
  on public.deal_events_falconcrm (to_stage_id, created_at desc);

create index if not exists idx_deal_events_falconcrm_loss_reason_created_at
  on public.deal_events_falconcrm (loss_reason_id, created_at desc);;
