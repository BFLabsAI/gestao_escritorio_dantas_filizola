alter table if exists public.products_falconcrm
  add column if not exists setup_price numeric(14,2);

alter table if exists public.products_falconcrm
  add column if not exists recurring_price numeric(14,2);

alter table if exists public.products_falconcrm
  add column if not exists pricing numeric(14,2);

update public.products_falconcrm
set setup_price = coalesce(setup_price, pricing)
where payment_plan in ('setup', 'setup_recurring');

update public.products_falconcrm
set recurring_price = coalesce(recurring_price, pricing)
where payment_plan in ('recurring', 'setup_recurring');

alter table if exists public.deal_products_falconcrm
  add column if not exists custom_setup_price numeric(14,2);

alter table if exists public.deal_products_falconcrm
  add column if not exists custom_recurring_price numeric(14,2);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'products_falconcrm_payment_plan_check'
  ) then
    alter table public.products_falconcrm
      add constraint products_falconcrm_payment_plan_check
      check (payment_plan in ('setup', 'setup_recurring', 'recurring'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'products_falconcrm_business_unit_check'
  ) then
    alter table public.products_falconcrm
      add constraint products_falconcrm_business_unit_check
      check (business_unit in ('service', 'equity', 'education'));
  end if;
end
$$;;
