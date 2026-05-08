-- Performance indexes for BF Tickets (Optimized for 200 conversations/day)

-- conversations_bf_tickets indexes
CREATE INDEX IF NOT EXISTS idx_conversations_remote_jid ON conversations_bf_tickets(remote_jid);
CREATE INDEX IF NOT EXISTS idx_conversations_status ON conversations_bf_tickets(status);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at ON conversations_bf_tickets(last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_is_group ON conversations_bf_tickets(is_group);
CREATE INDEX IF NOT EXISTS idx_conversations_group_tag ON conversations_bf_tickets(group_tag) WHERE group_tag IS NOT NULL;

-- messages_bf_tickets indexes (High-priority for message throughput)
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages_bf_tickets(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_message_id ON messages_bf_tickets(message_id);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages_bf_tickets(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_messages_from_me ON messages_bf_tickets(from_me);
CREATE INDEX IF NOT EXISTS idx_messages_status ON messages_bf_tickets(status);

-- Composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_messages_conversation_timestamp ON messages_bf_tickets(conversation_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_status_last_message ON conversations_bf_tickets(status, last_message_at DESC);

-- groups_bf_tickets indexes
CREATE INDEX IF NOT EXISTS idx_groups_group_jid ON groups_bf_tickets(group_jid);
CREATE INDEX IF NOT EXISTS idx_groups_updated_at ON groups_bf_tickets(updated_at DESC);

-- tagged_groups_bf_tickets indexes
CREATE INDEX IF NOT EXISTS idx_tagged_groups_group_id ON tagged_groups_bf_tickets(group_id);
CREATE INDEX IF NOT EXISTS idx_tagged_groups_is_active ON tagged_groups_bf_tickets(is_active);
CREATE INDEX IF NOT EXISTS idx_tagged_groups_tag_name ON tagged_groups_bf_tickets(tag_name);

-- media_files_bf_tickets indexes
CREATE INDEX IF NOT EXISTS idx_media_files_message_id ON media_files_bf_tickets(message_id);
CREATE INDEX IF NOT EXISTS idx_media_files_upload_status ON media_files_bf_tickets(upload_status);

-- JSONB indexes for optimized group queries (Using GIN for participants array)
CREATE INDEX IF NOT EXISTS idx_groups_participants_gin ON groups_bf_tickets USING GIN (participants);

-- Update table statistics for query optimizer
ANALYZE conversations_bf_tickets;
ANALYZE messages_bf_tickets;
ANALYZE groups_bf_tickets;
ANALYZE tagged_groups_bf_tickets;
ANALYZE media_files_bf_tickets;;
