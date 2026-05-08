
-- WhatsApp UAZAPI integration tables

create table if not exists public.whatsapp_instances_falconcrm (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_user_falconcrm(id) on delete cascade,
  name text not null,
  api_token_encrypted text not null,
  base_url text not null default 'https://bflabs.uazapi.com',
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table if not exists public.whatsapp_messages_falconcrm (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references public.deals_falconcrm(id) on delete cascade,
  instance_id uuid not null references public.whatsapp_instances_falconcrm(id) on delete cascade,
  contact_phone text not null,
  message_type text not null default 'text',
  content text not null,
  media_url text,
  media_type text,
  status text not null default 'pending',
  scheduled_at timestamp with time zone,
  sent_at timestamp with time zone,
  qstash_message_id text,
  error_message text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- Triggers for updated_at
drop trigger if exists trg_whatsapp_instances_updated_at on public.whatsapp_instances_falconcrm;
create trigger trg_whatsapp_instances_updated_at
before update on public.whatsapp_instances_falconcrm
for each row execute function public.set_updated_at_falconcrm();

drop trigger if exists trg_whatsapp_messages_updated_at on public.whatsapp_messages_falconcrm;
create trigger trg_whatsapp_messages_updated_at
before update on public.whatsapp_messages_falconcrm
for each row execute function public.set_updated_at_falconcrm();

-- Indexes
create index if not exists idx_whatsapp_messages_deal_id on public.whatsapp_messages_falconcrm(deal_id);
create index if not exists idx_whatsapp_messages_status on public.whatsapp_messages_falconcrm(status);
create index if not exists idx_whatsapp_instances_user_id on public.whatsapp_instances_falconcrm(user_id);

-- Grant permissions
grant select, insert, update, delete on public.whatsapp_instances_falconcrm to anon, authenticated;
grant select, insert, update, delete on public.whatsapp_messages_falconcrm to anon, authenticated;
;
