-- Agent conversations table
CREATE TABLE IF NOT EXISTS vibeagents_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  agent_type TEXT NOT NULL CHECK (agent_type IN ('mentor', 'arquiteto', 'criador', 'engenheiro', 'estrategista', 'analista')),
  title TEXT,
  initial_questions_answered BOOLEAN DEFAULT FALSE,
  state JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Agent messages table
CREATE TABLE IF NOT EXISTS vibeagents_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES vibeagents_conversations(id) ON DELETE CASCADE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Agent outputs table (structured deliverables)
CREATE TABLE IF NOT EXISTS vibeagents_outputs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES vibeagents_conversations(id) ON DELETE CASCADE NOT NULL,
  output_type TEXT NOT NULL,
  content JSONB NOT NULL,
  version INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_vibeagents_conversations_user_id ON vibeagents_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_vibeagents_conversations_agent_type ON vibeagents_conversations(agent_type);
CREATE INDEX IF NOT EXISTS idx_vibeagents_messages_conversation_id ON vibeagents_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_vibeagents_outputs_conversation_id ON vibeagents_outputs(conversation_id);

-- Enable Row Level Security
ALTER TABLE vibeagents_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE vibeagents_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE vibeagents_outputs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for vibeagents_conversations
CREATE POLICY "Users can view their own conversations"
  ON vibeagents_conversations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own conversations"
  ON vibeagents_conversations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conversations"
  ON vibeagents_conversations FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own conversations"
  ON vibeagents_conversations FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for vibeagents_messages
CREATE POLICY "Users can view messages in their conversations"
  ON vibeagents_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM vibeagents_conversations
      WHERE vibeagents_conversations.id = vibeagents_messages.conversation_id
      AND vibeagents_conversations.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert messages in their conversations"
  ON vibeagents_messages FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vibeagents_conversations
      WHERE vibeagents_conversations.id = vibeagents_messages.conversation_id
      AND vibeagents_conversations.user_id = auth.uid()
    )
  );

-- RLS Policies for vibeagents_outputs
CREATE POLICY "Users can view outputs in their conversations"
  ON vibeagents_outputs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM vibeagents_conversations
      WHERE vibeagents_conversations.id = vibeagents_outputs.conversation_id
      AND vibeagents_conversations.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert outputs in their conversations"
  ON vibeagents_outputs FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vibeagents_conversations
      WHERE vibeagents_conversations.id = vibeagents_outputs.conversation_id
      AND vibeagents_conversations.user_id = auth.uid()
    )
  );

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_vibeagents_conversations_updated_at
  BEFORE UPDATE ON vibeagents_conversations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();;
