-- falconcrm initial schema + rpc helpers for supabase
create extension if not exists pgcrypto;

create table if not exists public.app_user_falconcrm (
  id uuid primary key default gen_random_uuid(),
  email text,
  created_at timestamp with time zone not null default now()
);

create table if not exists public.pipelines_falconcrm (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_user_falconcrm(id) on delete cascade,
  name text not null,
  sort_order integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table if not exists public.pipeline_stages_falconcrm (
  id uuid primary key default gen_random_uuid(),
  pipeline_id uuid not null references public.pipelines_falconcrm(id) on delete cascade,
  name text not null,
  sort_order integer not null default 0,
  is_closed_won boolean not null default false,
  is_closed_lost boolean not null default false,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  is_mql boolean not null default false,
  is_sql boolean not null default false,
  is_won boolean not null default false,
  is_lost boolean not null default false
);

create table if not exists public.deal_types_falconcrm (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_user_falconcrm(id) on delete cascade,
  name text not null,
  sort_order integer not null default 0,
  created_at timestamp with time zone not null default now()
);

create table if not exists public.deals_falconcrm (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_user_falconcrm(id) on delete cascade,
  pipeline_id uuid not null references public.pipelines_falconcrm(id) on delete cascade,
  stage_id uuid not null references public.pipeline_stages_falconcrm(id),
  deal_type_id uuid not null references public.deal_types_falconcrm(id),
  title text not null,
  company_name text,
  amount numeric,
  probability integer not null default 50,
  expected_close_date date,
  is_closed boolean not null default false,
  closed_at timestamp with time zone,
  sort_order integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table if not exists public.deal_contacts_falconcrm (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references public.deals_falconcrm(id) on delete cascade,
  name text,
  role_title text,
  phone text not null,
  email text,
  notes text,
  is_primary boolean not null default false,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table if not exists public.deal_next_actions_falconcrm (
  deal_id uuid primary key references public.deals_falconcrm(id) on delete cascade,
  action_type text not null,
  description text not null,
  due_at timestamp with time zone not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table if not exists public.deal_notes_falconcrm (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references public.deals_falconcrm(id) on delete cascade,
  note text not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table if not exists public.tags_falconcrm (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_user_falconcrm(id) on delete cascade,
  name text not null,
  color text,
  created_at timestamp with time zone not null default now()
);

create table if not exists public.deal_tags_falconcrm (
  deal_id uuid not null references public.deals_falconcrm(id) on delete cascade,
  tag_id uuid not null references public.tags_falconcrm(id) on delete cascade,
  created_at timestamp with time zone not null default now(),
  primary key (deal_id, tag_id)
);

create table if not exists public.tasks_falconcrm (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_user_falconcrm(id) on delete cascade,
  deal_id uuid references public.deals_falconcrm(id) on delete cascade,
  title text not null,
  description text,
  status text not null default 'Now',
  due_at timestamp with time zone,
  completed_at timestamp with time zone,
  sort_order integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table if not exists public.task_tags_falconcrm (
  task_id uuid not null references public.tasks_falconcrm(id) on delete cascade,
  tag_id uuid not null references public.tags_falconcrm(id) on delete cascade,
  created_at timestamp with time zone not null default now(),
  primary key (task_id, tag_id)
);

create table if not exists public.calendar_events_falconcrm (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_user_falconcrm(id) on delete cascade,
  title text not null,
  event_type text not null,
  starts_at timestamp with time zone not null,
  ends_at timestamp with time zone,
  location text,
  notes text,
  deal_id uuid references public.deals_falconcrm(id) on delete set null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table if not exists public.deal_custom_fields_falconcrm (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_user_falconcrm(id) on delete cascade,
  key text not null,
  label text not null,
  field_type text not null,
  is_required boolean not null default false,
  sort_order integer not null default 0,
  options jsonb,
  created_at timestamp with time zone not null default now()
);

create table if not exists public.deal_custom_field_values_falconcrm (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references public.deals_falconcrm(id) on delete cascade,
  field_id uuid not null references public.deal_custom_fields_falconcrm(id) on delete cascade,
  value_text text,
  value_number numeric,
  value_date date,
  value_bool boolean,
  value_json jsonb,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table if not exists public.user_settings_falconcrm (
  user_id uuid primary key references public.app_user_falconcrm(id) on delete cascade,
  stalled_deal_days integer not null default 7,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create or replace function public.set_updated_at_falconcrm()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.validate_deal_stage_belongs_to_pipeline_falconcrm()
returns trigger
language plpgsql
as $$
declare
  stage_pipeline uuid;
begin
  select pipeline_id into stage_pipeline
  from public.pipeline_stages_falconcrm
  where id = new.stage_id;

  if stage_pipeline is null then
    raise exception 'stage_id inválido';
  end if;

  if stage_pipeline <> new.pipeline_id then
    raise exception 'stage_id não pertence ao pipeline_id do deal';
  end if;

  return new;
end;
$$;

create or replace function public.enforce_deal_has_contact_falconcrm()
returns trigger
language plpgsql
as $$
declare
  cnt int;
begin
  select count(*) into cnt
  from public.deal_contacts_falconcrm
  where deal_id = new.id
    and coalesce(trim(phone), '') <> '';

  if cnt < 1 then
    raise exception 'Deal precisa ter pelo menos 1 contato com telefone';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_calendar_events_updated_at on public.calendar_events_falconcrm;
create trigger trg_calendar_events_updated_at
before update on public.calendar_events_falconcrm
for each row execute function public.set_updated_at_falconcrm();

drop trigger if exists trg_deal_contacts_updated_at on public.deal_contacts_falconcrm;
create trigger trg_deal_contacts_updated_at
before update on public.deal_contacts_falconcrm
for each row execute function public.set_updated_at_falconcrm();

drop trigger if exists trg_deal_custom_field_values_updated_at on public.deal_custom_field_values_falconcrm;
create trigger trg_deal_custom_field_values_updated_at
before update on public.deal_custom_field_values_falconcrm
for each row execute function public.set_updated_at_falconcrm();

drop trigger if exists trg_deal_next_actions_updated_at on public.deal_next_actions_falconcrm;
create trigger trg_deal_next_actions_updated_at
before update on public.deal_next_actions_falconcrm
for each row execute function public.set_updated_at_falconcrm();

drop trigger if exists trg_deal_notes_updated_at on public.deal_notes_falconcrm;
create trigger trg_deal_notes_updated_at
before update on public.deal_notes_falconcrm
for each row execute function public.set_updated_at_falconcrm();

drop trigger if exists trg_deals_updated_at on public.deals_falconcrm;
create trigger trg_deals_updated_at
before update on public.deals_falconcrm
for each row execute function public.set_updated_at_falconcrm();

drop trigger if exists trg_validate_deal_stage on public.deals_falconcrm;
create trigger trg_validate_deal_stage
before insert or update of pipeline_id, stage_id on public.deals_falconcrm
for each row execute function public.validate_deal_stage_belongs_to_pipeline_falconcrm();

drop trigger if exists trg_deal_must_have_contact on public.deals_falconcrm;
create constraint trigger trg_deal_must_have_contact
after insert or update on public.deals_falconcrm
deferrable initially deferred
for each row execute function public.enforce_deal_has_contact_falconcrm();

drop trigger if exists trg_pipeline_stages_updated_at on public.pipeline_stages_falconcrm;
create trigger trg_pipeline_stages_updated_at
before update on public.pipeline_stages_falconcrm
for each row execute function public.set_updated_at_falconcrm();

drop trigger if exists trg_pipelines_updated_at on public.pipelines_falconcrm;
create trigger trg_pipelines_updated_at
before update on public.pipelines_falconcrm
for each row execute function public.set_updated_at_falconcrm();

drop trigger if exists trg_tasks_updated_at on public.tasks_falconcrm;
create trigger trg_tasks_updated_at
before update on public.tasks_falconcrm
for each row execute function public.set_updated_at_falconcrm();

drop trigger if exists trg_user_settings_updated_at on public.user_settings_falconcrm;
create trigger trg_user_settings_updated_at
before update on public.user_settings_falconcrm
for each row execute function public.set_updated_at_falconcrm();

create or replace function public.exec_sql_falconcrm(query_falconcrm text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  begin
    execute format('select coalesce(jsonb_agg(row_to_json(t)), ''[]''::jsonb) from (%s) t', query_falconcrm)
      into result;
    return coalesce(result, '[]'::jsonb);
  exception when others then
    execute query_falconcrm;
    return '[]'::jsonb;
  end;
end;
$$;

create or replace function public.create_deal_with_contact_falconcrm(
  p_user_id_falconcrm uuid,
  p_pipeline_id_falconcrm uuid,
  p_stage_id_falconcrm uuid,
  p_deal_type_id_falconcrm uuid,
  p_title_falconcrm text,
  p_company_name_falconcrm text,
  p_amount_falconcrm numeric,
  p_probability_falconcrm integer,
  p_expected_close_date_falconcrm date,
  p_contact_name_falconcrm text,
  p_contact_role_falconcrm text,
  p_contact_phone_falconcrm text,
  p_contact_email_falconcrm text,
  p_tags_falconcrm uuid[] default '{}',
  p_next_action_type_falconcrm text default null,
  p_next_action_description_falconcrm text default null,
  p_next_action_due_at_falconcrm timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deal_id_falconcrm uuid;
  v_tag_id_falconcrm uuid;
begin
  if coalesce(trim(p_contact_phone_falconcrm), '') = '' then
    raise exception 'Deal precisa ter pelo menos 1 contato com telefone';
  end if;

  set constraints all deferred;

  insert into public.deals_falconcrm (
    user_id, pipeline_id, stage_id, deal_type_id, title, company_name,
    amount, probability, expected_close_date
  ) values (
    p_user_id_falconcrm,
    p_pipeline_id_falconcrm,
    p_stage_id_falconcrm,
    p_deal_type_id_falconcrm,
    p_title_falconcrm,
    p_company_name_falconcrm,
    p_amount_falconcrm,
    p_probability_falconcrm,
    p_expected_close_date_falconcrm
  ) returning id into v_deal_id_falconcrm;

  insert into public.deal_contacts_falconcrm (deal_id, name, role_title, phone, email, notes, is_primary)
  values (
    v_deal_id_falconcrm,
    p_contact_name_falconcrm,
    coalesce(p_contact_role_falconcrm, ''),
    p_contact_phone_falconcrm,
    coalesce(p_contact_email_falconcrm, ''),
    '',
    true
  );

  if array_length(p_tags_falconcrm, 1) is not null then
    foreach v_tag_id_falconcrm in array p_tags_falconcrm loop
      insert into public.deal_tags_falconcrm (deal_id, tag_id)
      values (v_deal_id_falconcrm, v_tag_id_falconcrm)
      on conflict do nothing;
    end loop;
  end if;

  if p_next_action_type_falconcrm is not null
     and p_next_action_description_falconcrm is not null
     and p_next_action_due_at_falconcrm is not null then
    insert into public.deal_next_actions_falconcrm (deal_id, action_type, description, due_at)
    values (
      v_deal_id_falconcrm,
      p_next_action_type_falconcrm,
      p_next_action_description_falconcrm,
      p_next_action_due_at_falconcrm
    );
  end if;

  return v_deal_id_falconcrm;
end;
$$;

grant usage on schema public to anon, authenticated;
grant execute on function public.exec_sql_falconcrm(text) to anon, authenticated;
grant execute on function public.create_deal_with_contact_falconcrm(
  uuid, uuid, uuid, uuid, text, text, numeric, integer, date,
  text, text, text, text, uuid[], text, text, timestamptz
) to anon, authenticated;;
