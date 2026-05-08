
-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. TENANTS
create table if not exists tenants_rastreia_lead_antyv2 (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  slug text unique not null,
  plan text default 'free',
  created_at timestamptz default now()
);

-- 2. PROFILES (Users)
create table if not exists profiles_rastreia_lead_antyv2 (
  id uuid primary key references auth.users(id),
  tenant_id uuid references tenants_rastreia_lead_antyv2(id) not null,
  email text,
  full_name text,
  avatar_url text,
  role text default 'member',
  created_at timestamptz default now()
);

alter table profiles_rastreia_lead_antyv2 enable row level security;

-- Drop policy if exists to allow idempotency (Supabase doesn't support IF NOT EXISTS for policies easily in one block, but we can try just creating it. If it fails, it fails, usually policies persist)
-- A trick is to drop it first or ignore error. For now, assuming fresh start or simple error on duplication.
drop policy if exists "Users can view own profile" on profiles_rastreia_lead_antyv2;
create policy "Users can view own profile" on profiles_rastreia_lead_antyv2
  for select using (auth.uid() = id);

-- 3. GENERIC RLS FUNCTION
create or replace function get_user_tenant_id()
returns uuid as $$
  select tenant_id from profiles_rastreia_lead_antyv2 where id = auth.uid() limit 1;
$$ language sql security definer;

-- 4. CRM CORE TABLES including PIPELINES
create table if not exists pipelines_rastreia_lead_antyv2 (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants_rastreia_lead_antyv2(id) not null,
  name text not null,
  is_default boolean default false,
  created_at timestamptz default now()
);
alter table pipelines_rastreia_lead_antyv2 enable row level security;
drop policy if exists "Tenant Access" on pipelines_rastreia_lead_antyv2;
create policy "Tenant Access" on pipelines_rastreia_lead_antyv2 using (tenant_id = get_user_tenant_id());

create table if not exists stages_rastreia_lead_antyv2 (
  id uuid primary key default uuid_generate_v4(),
  pipeline_id uuid references pipelines_rastreia_lead_antyv2(id) not null,
  tenant_id uuid references tenants_rastreia_lead_antyv2(id) not null, 
  name text not null,
  position int default 0,
  color text
);
alter table stages_rastreia_lead_antyv2 enable row level security;
drop policy if exists "Tenant Access" on stages_rastreia_lead_antyv2;
create policy "Tenant Access" on stages_rastreia_lead_antyv2 using (tenant_id = get_user_tenant_id());

create table if not exists companies_rastreia_lead_antyv2 (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants_rastreia_lead_antyv2(id) not null,
  name text not null,
  domain text,
  logo_url text,
  industry text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table companies_rastreia_lead_antyv2 enable row level security;
drop policy if exists "Tenant Access" on companies_rastreia_lead_antyv2;
create policy "Tenant Access" on companies_rastreia_lead_antyv2 using (tenant_id = get_user_tenant_id());

create table if not exists contacts_rastreia_lead_antyv2 (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants_rastreia_lead_antyv2(id) not null,
  company_id uuid references companies_rastreia_lead_antyv2(id),
  first_name text not null,
  last_name text,
  email text,
  phone text,
  position text,
  avatar_url text,
  created_at timestamptz default now()
);
alter table contacts_rastreia_lead_antyv2 enable row level security;
drop policy if exists "Tenant Access" on contacts_rastreia_lead_antyv2;
create policy "Tenant Access" on contacts_rastreia_lead_antyv2 using (tenant_id = get_user_tenant_id());

create table if not exists deals_rastreia_lead_antyv2 (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants_rastreia_lead_antyv2(id) not null,
  stage_id uuid references stages_rastreia_lead_antyv2(id),
  company_id uuid references companies_rastreia_lead_antyv2(id),
  contact_id uuid references contacts_rastreia_lead_antyv2(id),
  owner_id uuid references profiles_rastreia_lead_antyv2(id),
  title text not null,
  value decimal default 0,
  currency text default 'USD',
  status text default 'open',
  probability int,
  expected_close_date timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table deals_rastreia_lead_antyv2 enable row level security;
drop policy if exists "Tenant Access" on deals_rastreia_lead_antyv2;
create policy "Tenant Access" on deals_rastreia_lead_antyv2 using (tenant_id = get_user_tenant_id());

create table if not exists events_rastreia_lead_antyv2 (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants_rastreia_lead_antyv2(id) not null,
  owner_id uuid references profiles_rastreia_lead_antyv2(id),
  title text not null,
  description text,
  type text,
  start_time timestamptz not null,
  end_time timestamptz not null,
  location text,
  meeting_url text,
  attendees jsonb,
  created_at timestamptz default now()
);
alter table events_rastreia_lead_antyv2 enable row level security;
drop policy if exists "Tenant Access" on events_rastreia_lead_antyv2;
create policy "Tenant Access" on events_rastreia_lead_antyv2 using (tenant_id = get_user_tenant_id());

-- 5. WHATSAPP & COMMUNICATION
create table if not exists whatsapp_instances_rastreia_lead_antyv2 (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants_rastreia_lead_antyv2(id) not null,
  uazapi_id text,
  name text,
  token text,
  status text,
  qr_code text,
  last_qrcode_gen timestamptz,
  profile_name text,
  profile_pic_url text,
  owner_jid text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table whatsapp_instances_rastreia_lead_antyv2 enable row level security;
drop policy if exists "Tenant Access" on whatsapp_instances_rastreia_lead_antyv2;
create policy "Tenant Access" on whatsapp_instances_rastreia_lead_antyv2 using (tenant_id = get_user_tenant_id());

create table if not exists conversations_rastreia_lead_antyv2 (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants_rastreia_lead_antyv2(id) not null,
  instance_id uuid references whatsapp_instances_rastreia_lead_antyv2(id) not null,
  contact_id uuid references contacts_rastreia_lead_antyv2(id),
  remote_jid text not null,
  platform text default 'whatsapp',
  status text default 'open',
  unread_count int default 0,
  last_msg_text text,
  last_msg_at timestamptz default now()
);
alter table conversations_rastreia_lead_antyv2 enable row level security;
drop policy if exists "Tenant Access" on conversations_rastreia_lead_antyv2;
create policy "Tenant Access" on conversations_rastreia_lead_antyv2 using (tenant_id = get_user_tenant_id());

create table if not exists chat_messages_rastreia_lead_antyv2 (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants_rastreia_lead_antyv2(id) not null,
  instance_id uuid references whatsapp_instances_rastreia_lead_antyv2(id) not null,
  conversation_id uuid references conversations_rastreia_lead_antyv2(id) not null,
  wamid text,
  remote_jid text,
  from_me boolean,
  type text,
  content text,
  media_url text,
  media_mimetype text,
  media_filename text,
  status text,
  qstash_message_id text,
  error_message text,
  timestamp bigint,
  created_at timestamptz default now()
);
alter table chat_messages_rastreia_lead_antyv2 enable row level security;
drop policy if exists "Tenant Access" on chat_messages_rastreia_lead_antyv2;
create policy "Tenant Access" on chat_messages_rastreia_lead_antyv2 using (tenant_id = get_user_tenant_id());

create table if not exists api_logs_rastreia_lead_antyv2 (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants_rastreia_lead_antyv2(id) not null,
  instance_id uuid,
  direction text,
  endpoint text,
  payload text,
  response_code int,
  response_body text,
  created_at timestamptz default now()
);
alter table api_logs_rastreia_lead_antyv2 enable row level security;
drop policy if exists "Tenant Access" on api_logs_rastreia_lead_antyv2;
create policy "Tenant Access" on api_logs_rastreia_lead_antyv2 using (tenant_id = get_user_tenant_id());
;
