-- Create rastreia_lead_kiro_conversations table
CREATE TABLE rastreia_lead_kiro_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
  contact_id UUID NOT NULL REFERENCES rastreia_lead_kiro_contacts(id) ON DELETE CASCADE,
  channel TEXT NOT NULL CHECK (channel IN ('whatsapp', 'instagram', 'email')),
  channel_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
  assigned_to UUID REFERENCES rastreia_lead_kiro_users(id) ON DELETE SET NULL,
  last_message_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unread_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_kiro_conversations_organization_id ON rastreia_lead_kiro_conversations(organization_id);
CREATE INDEX idx_kiro_conversations_contact_id ON rastreia_lead_kiro_conversations(contact_id);
CREATE INDEX idx_kiro_conversations_assigned_to ON rastreia_lead_kiro_conversations(assigned_to);
CREATE INDEX idx_kiro_conversations_status ON rastreia_lead_kiro_conversations(status);
CREATE INDEX idx_kiro_conversations_last_message_at ON rastreia_lead_kiro_conversations(last_message_at DESC);

-- Create rastreia_lead_kiro_messages table
CREATE TABLE rastreia_lead_kiro_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES rastreia_lead_kiro_conversations(id) ON DELETE CASCADE,
  sender_type TEXT NOT NULL CHECK (sender_type IN ('contact', 'user', 'system')),
  sender_id UUID,
  content TEXT,
  media_type TEXT NOT NULL DEFAULT 'text' CHECK (media_type IN ('text', 'image', 'audio', 'video', 'document')),
  media_url TEXT,
  audio_transcription TEXT,
  is_internal_note BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_kiro_messages_conversation_id ON rastreia_lead_kiro_messages(conversation_id);
CREATE INDEX idx_kiro_messages_created_at ON rastreia_lead_kiro_messages(created_at DESC);
CREATE INDEX idx_kiro_messages_is_internal_note ON rastreia_lead_kiro_messages(is_internal_note);

-- Enable Row Level Security
ALTER TABLE rastreia_lead_kiro_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE rastreia_lead_kiro_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for rastreia_lead_kiro_conversations
-- Organization isolation policy
CREATE POLICY "rastreia_lead_kiro_conversations_org_isolation"
ON rastreia_lead_kiro_conversations
FOR ALL
USING (
  organization_id IN (
    SELECT organization_id 
    FROM rastreia_lead_kiro_users 
    WHERE id = auth.uid()
  )
);

-- Consultant access policy (only assigned conversations)
CREATE POLICY "rastreia_lead_kiro_conversations_consultant_access"
ON rastreia_lead_kiro_conversations
FOR SELECT
USING (
  organization_id IN (
    SELECT organization_id 
    FROM rastreia_lead_kiro_users 
    WHERE id = auth.uid()
  )
  AND (
    (SELECT role FROM rastreia_lead_kiro_users WHERE id = auth.uid()) IN ('super_admin', 'manager')
    OR assigned_to = auth.uid()
  )
);

-- RLS Policies for rastreia_lead_kiro_messages
-- Messages inherit conversation access
CREATE POLICY "rastreia_lead_kiro_messages_conversation_access"
ON rastreia_lead_kiro_messages
FOR ALL
USING (
  conversation_id IN (
    SELECT id 
    FROM rastreia_lead_kiro_conversations 
    WHERE organization_id IN (
      SELECT organization_id 
      FROM rastreia_lead_kiro_users 
      WHERE id = auth.uid()
    )
  )
);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_conversations_updated_at
BEFORE UPDATE ON rastreia_lead_kiro_conversations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create trigger to update last_message_at and unread_count on new message
CREATE OR REPLACE FUNCTION update_conversation_on_new_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE rastreia_lead_kiro_conversations
  SET 
    last_message_at = NEW.created_at,
    unread_count = CASE 
      WHEN NEW.sender_type = 'contact' AND NOT NEW.is_internal_note THEN unread_count + 1
      ELSE unread_count
    END
  WHERE id = NEW.conversation_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_conversation_on_message
AFTER INSERT ON rastreia_lead_kiro_messages
FOR EACH ROW
EXECUTE FUNCTION update_conversation_on_new_message();

-- Enable Realtime for conversations and messages
ALTER PUBLICATION supabase_realtime ADD TABLE rastreia_lead_kiro_conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE rastreia_lead_kiro_messages;;
