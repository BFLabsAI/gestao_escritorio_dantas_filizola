-- BF Tickets Database Schema
-- Phase 1: Complete table implementation with constraints and relationships

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. conversations_bf_tickets table
CREATE TABLE IF NOT EXISTS conversations_bf_tickets (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    remote_jid text UNIQUE NOT NULL,
    contact_name text,
    contact_phone text,
    is_group boolean DEFAULT false,
    group_tag text,
    status text CHECK (status IN ('open', 'pending', 'closed')) DEFAULT 'open',
    last_message_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 2. messages_bf_tickets table
CREATE TABLE IF NOT EXISTS messages_bf_tickets (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id uuid NOT NULL REFERENCES conversations_bf_tickets(id) ON DELETE CASCADE,
    message_id text UNIQUE NOT NULL,
    from_me boolean DEFAULT false,
    sender_name text,
    sender_phone text,
    message_type text CHECK (message_type IN ('text', 'image', 'video', 'audio', 'document', 'sticker')),
    content_text text,
    media_url text,
    media_mimetype text,
    media_size bigint,
    timestamp timestamptz NOT NULL,
    status text CHECK (status IN ('sent', 'delivered', 'read', 'failed')) DEFAULT 'sent',
    created_at timestamptz DEFAULT now()
);

-- 3. groups_bf_tickets table
CREATE TABLE IF NOT EXISTS groups_bf_tickets (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_jid text UNIQUE NOT NULL,
    group_name text NOT NULL,
    group_subject text,
    participants jsonb,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 4. tagged_groups_bf_tickets table
CREATE TABLE IF NOT EXISTS tagged_groups_bf_tickets (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id uuid NOT NULL REFERENCES groups_bf_tickets(id) ON DELETE CASCADE,
    tag_name text NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    UNIQUE(group_id, tag_name)
);

-- 5. media_files_bf_tickets table
CREATE TABLE IF NOT EXISTS media_files_bf_tickets (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id uuid NOT NULL REFERENCES messages_bf_tickets(id) ON DELETE CASCADE,
    file_path text NOT NULL,
    file_size bigint,
    mime_type text,
    upload_status text CHECK (upload_status IN ('pending', 'completed', 'failed')) DEFAULT 'pending',
    created_at timestamptz DEFAULT now()
);

-- Create performance indexes
-- Indexes for conversations_bf_tickets
CREATE INDEX IF NOT EXISTS idx_conversations_status ON conversations_bf_tickets(status);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message ON conversations_bf_tickets(last_message_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_conversations_remote_jid ON conversations_bf_tickets(remote_jid);

-- Indexes for messages_bf_tickets
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages_bf_tickets(conversation_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_messages_message_id ON messages_bf_tickets(message_id);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages_bf_tickets(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_messages_from_me ON messages_bf_tickets(from_me);

-- Indexes for groups_bf_tickets
CREATE INDEX IF NOT EXISTS idx_groups_group_jid ON groups_bf_tickets(group_jid);
CREATE INDEX IF NOT EXISTS idx_groups_name ON groups_bf_tickets(group_name);

-- Indexes for tagged_groups_bf_tickets
CREATE INDEX IF NOT EXISTS idx_tagged_groups_active ON tagged_groups_bf_tickets(is_active, group_id);
CREATE INDEX IF NOT EXISTS idx_tagged_groups_tag_name ON tagged_groups_bf_tickets(tag_name);

-- Indexes for media_files_bf_tickets
CREATE INDEX IF NOT EXISTS idx_media_files_message ON media_files_bf_tickets(message_id);
CREATE INDEX IF NOT EXISTS idx_media_files_upload_status ON media_files_bf_tickets(upload_status);

-- Enable Row Level Security on all tables
ALTER TABLE conversations_bf_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages_bf_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups_bf_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE tagged_groups_bf_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE media_files_bf_tickets ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for single-user system
-- Policies for conversations_bf_tickets
CREATE POLICY "Enable all operations for single user system" ON conversations_bf_tickets
    FOR ALL USING (true)
    WITH CHECK (true);

-- Policies for messages_bf_tickets
CREATE POLICY "Enable all operations for single user system" ON messages_bf_tickets
    FOR ALL USING (true)
    WITH CHECK (true);

-- Policies for groups_bf_tickets
CREATE POLICY "Enable all operations for single user system" ON groups_bf_tickets
    FOR ALL USING (true)
    WITH CHECK (true);

-- Policies for tagged_groups_bf_tickets
CREATE POLICY "Enable all operations for single user system" ON tagged_groups_bf_tickets
    FOR ALL USING (true)
    WITH CHECK (true);

-- Policies for media_files_bf_tickets
CREATE POLICY "Enable all operations for single user system" ON media_files_bf_tickets
    FOR ALL USING (true)
    WITH CHECK (true);

-- Create functions for automatic updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON conversations_bf_tickets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_groups_updated_at BEFORE UPDATE ON groups_bf_tickets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create helpful views for common queries
CREATE OR REPLACE VIEW active_tagged_groups AS
SELECT 
    tg.id,
    tg.group_id,
    tg.tag_name,
    g.group_jid,
    g.group_name,
    g.group_subject,
    g.participants,
    g.created_at as group_created_at,
    g.updated_at as group_updated_at
FROM tagged_groups_bf_tickets tg
JOIN groups_bf_tickets g ON tg.group_id = g.id
WHERE tg.is_active = true;

CREATE OR REPLACE VIEW conversation_summary AS
SELECT 
    c.id,
    c.remote_jid,
    c.contact_name,
    c.contact_phone,
    c.is_group,
    c.group_tag,
    c.status,
    c.last_message_at,
    c.created_at,
    c.updated_at,
    COUNT(m.id) as message_count,
    MAX(m.timestamp) as latest_message_timestamp
FROM conversations_bf_tickets c
LEFT JOIN messages_bf_tickets m ON c.id = m.conversation_id
GROUP BY c.id, c.remote_jid, c.contact_name, c.contact_phone, c.is_group, c.group_tag, c.status, c.last_message_at, c.created_at, c.updated_at;;
