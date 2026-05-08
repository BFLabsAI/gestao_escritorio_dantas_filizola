create table if not exists public.agent_chats_falconcrm (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_user_falconcrm(id) on delete cascade,
  title text not null default 'Novo chat',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.agent_messages_falconcrm (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.agent_chats_falconcrm(id) on delete cascade,
  role text not null check (role in ('system', 'user', 'assistant', 'tool')),
  content text not null,
  meta jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.agent_tool_runs_falconcrm (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.agent_chats_falconcrm(id) on delete cascade,
  tool_name text not null,
  input_json jsonb,
  output_json jsonb,
  status text not null default 'success',
  created_at timestamptz not null default now()
);

create index if not exists idx_agent_chats_user_falconcrm
  on public.agent_chats_falconcrm(user_id, updated_at desc);

create index if not exists idx_agent_messages_chat_falconcrm
  on public.agent_messages_falconcrm(chat_id, created_at asc);

create index if not exists idx_agent_tool_runs_chat_falconcrm
  on public.agent_tool_runs_falconcrm(chat_id, created_at desc);

drop trigger if exists trg_agent_chats_updated_at on public.agent_chats_falconcrm;
create trigger trg_agent_chats_updated_at
before update on public.agent_chats_falconcrm
for each row execute function public.set_updated_at_falconcrm();;
