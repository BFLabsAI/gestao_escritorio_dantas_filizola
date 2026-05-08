create table if not exists public.products_falconcrm (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_user_falconcrm(id) on delete cascade,
  name text not null,
  details text,
  pricing numeric(14,2) not null default 0,
  payment_plan text not null default 'setup',
  business_unit text not null default 'service',
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint products_falconcrm_payment_plan_check check (payment_plan in ('setup', 'setup_recurring', 'recurring')),
  constraint products_falconcrm_business_unit_check check (business_unit in ('service', 'equity', 'education'))
);

create table if not exists public.deal_products_falconcrm (
  deal_id uuid primary key references public.deals_falconcrm(id) on delete cascade,
  product_id uuid not null references public.products_falconcrm(id) on delete restrict,
  custom_price numeric(14,2),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create index if not exists idx_products_falconcrm_user_id on public.products_falconcrm(user_id);
create index if not exists idx_deal_products_falconcrm_product_id on public.deal_products_falconcrm(product_id);;
