create table if not exists copy_agent_disparador_r7_treinamentos (
  id uuid default gen_random_uuid() primary key,
  user_id text not null,
  chat_id uuid not null,
  session_name text,
  message_role text not null,
  message_content text not null,
  template_used text,
  metadata jsonb,
  created_at timestamptz default now()
);

-- Enable RLS
alter table copy_agent_disparador_r7_treinamentos enable row level security;

-- Policies
create policy "Users can view their own chats"
  on copy_agent_disparador_r7_treinamentos for select
  using (true); -- Using true for now as user_id is hardcoded 'default-user'

create policy "Users can insert their own chats"
  on copy_agent_disparador_r7_treinamentos for insert
  with check (true);

create policy "Users can update their own chats"
  on copy_agent_disparador_r7_treinamentos for update
  using (true);

create policy "Users can delete their own chats"
  on copy_agent_disparador_r7_treinamentos for delete
  using (true);

-- Notify to reload schema cache
NOTIFY pgrst, 'reload config';;
