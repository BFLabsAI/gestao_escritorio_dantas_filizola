create table if not exists public.loss_reasons_falconcrm (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_user_falconcrm(id) on delete cascade,
  name text not null,
  "order" integer not null default 0,
  created_at timestamp with time zone not null default now()
);

create index if not exists idx_loss_reasons_falconcrm_user_order
  on public.loss_reasons_falconcrm (user_id, "order");

alter table public.deals_falconcrm
  add column if not exists loss_reason_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'deals_falconcrm_loss_reason_id_fkey'
  ) then
    alter table public.deals_falconcrm
      add constraint deals_falconcrm_loss_reason_id_fkey
      foreign key (loss_reason_id)
      references public.loss_reasons_falconcrm(id)
      on delete set null;
  end if;
end
$$;

create index if not exists idx_deals_falconcrm_loss_reason_id
  on public.deals_falconcrm (loss_reason_id);;
