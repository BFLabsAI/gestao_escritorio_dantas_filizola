-- Canais de comunicação
CREATE TABLE IF NOT EXISTS channels_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('public', 'private', 'dm')),
  project_id UUID REFERENCES projects_gestao_projetos(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users_gestao_projetos(id)
);

-- Membros de canais
CREATE TABLE IF NOT EXISTS channel_members_gestao_projetos (
  channel_id UUID REFERENCES channels_gestao_projetos(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users_gestao_projetos(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (channel_id, user_id)
);

-- Mensagens
CREATE TABLE IF NOT EXISTS messages_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID REFERENCES channels_gestao_projetos(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users_gestao_projetos(id),
  content TEXT NOT NULL,
  mentions UUID[] DEFAULT '{}',
  task_refs UUID[] DEFAULT '{}',
  project_refs UUID[] DEFAULT '{}',
  thread_parent_id UUID REFERENCES messages_gestao_projetos(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reações
CREATE TABLE IF NOT EXISTS message_reactions_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID REFERENCES messages_gestao_projetos(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users_gestao_projetos(id) ON DELETE CASCADE,
  emoji VARCHAR(10) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id, emoji)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_messages_channel_id ON messages_gestao_projetos(channel_id);
CREATE INDEX IF NOT EXISTS idx_messages_thread_parent_id ON messages_gestao_projetos(thread_parent_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages_gestao_projetos(created_at);
CREATE INDEX IF NOT EXISTS idx_channels_project_id ON channels_gestao_projetos(project_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id ON message_reactions_gestao_projetos(message_id);;
