create extension if not exists pgcrypto;

do $$
begin
  create type public.chat_role_dantas_filizola as enum (
    'system',
    'user',
    'assistant'
  );
exception
  when duplicate_object then null;
end $$;

create table if not exists public.chats_dantas_filizola (
  id uuid primary key default gen_random_uuid(),
  title text not null default 'Nova conversa',
  model text not null default 'x-ai/grok-4.1-fast',
  status text not null default 'idle',
  last_message_preview text,
  last_message_at timestamptz,
  total_messages integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_messages_dantas_filizola (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats_dantas_filizola(id) on delete cascade,
  role public.chat_role_dantas_filizola not null,
  content text not null,
  provider text,
  model text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.chats_dantas_filizola disable row level security;
alter table public.chat_messages_dantas_filizola disable row level security;

create index if not exists chats_dantas_filizola_updated_idx
  on public.chats_dantas_filizola (updated_at desc);

create index if not exists chat_messages_dantas_filizola_chat_created_idx
  on public.chat_messages_dantas_filizola (chat_id, created_at asc);

create or replace function public.touch_chats_dantas_filizola_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_touch_chats_dantas_filizola_updated_at
  on public.chats_dantas_filizola;

create trigger trg_touch_chats_dantas_filizola_updated_at
before update on public.chats_dantas_filizola
for each row execute function public.touch_chats_dantas_filizola_updated_at();;
