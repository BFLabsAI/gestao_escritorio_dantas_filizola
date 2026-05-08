-- Enable RLS on chat tables
ALTER TABLE channels_gestao_projetos ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages_gestao_projetos ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions_gestao_projetos ENABLE ROW LEVEL SECURITY;
ALTER TABLE channel_members_gestao_projetos ENABLE ROW LEVEL SECURITY;

-- Channels: authenticated users can read all channels
CREATE POLICY "channels_select_policy" ON channels_gestao_projetos
  FOR SELECT TO authenticated USING (true);

-- Channels: authenticated users can insert channels
CREATE POLICY "channels_insert_policy" ON channels_gestao_projetos
  FOR INSERT TO authenticated WITH CHECK (true);

-- Channels: users can update channels they created
CREATE POLICY "channels_update_policy" ON channels_gestao_projetos
  FOR UPDATE TO authenticated USING (created_by = auth.uid());

-- Channels: users can delete channels they created
CREATE POLICY "channels_delete_policy" ON channels_gestao_projetos
  FOR DELETE TO authenticated USING (created_by = auth.uid());

-- Messages: authenticated users can read all messages
CREATE POLICY "messages_select_policy" ON messages_gestao_projetos
  FOR SELECT TO authenticated USING (true);

-- Messages: authenticated users can insert messages
CREATE POLICY "messages_insert_policy" ON messages_gestao_projetos
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- Messages: users can update their own messages
CREATE POLICY "messages_update_policy" ON messages_gestao_projetos
  FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- Messages: users can delete their own messages
CREATE POLICY "messages_delete_policy" ON messages_gestao_projetos
  FOR DELETE TO authenticated USING (user_id = auth.uid());

-- Reactions: authenticated users can read all reactions
CREATE POLICY "reactions_select_policy" ON message_reactions_gestao_projetos
  FOR SELECT TO authenticated USING (true);

-- Reactions: authenticated users can add reactions
CREATE POLICY "reactions_insert_policy" ON message_reactions_gestao_projetos
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- Reactions: users can delete their own reactions
CREATE POLICY "reactions_delete_policy" ON message_reactions_gestao_projetos
  FOR DELETE TO authenticated USING (user_id = auth.uid());

-- Channel members: authenticated users can read all members
CREATE POLICY "channel_members_select_policy" ON channel_members_gestao_projetos
  FOR SELECT TO authenticated USING (true);

-- Channel members: authenticated users can join channels
CREATE POLICY "channel_members_insert_policy" ON channel_members_gestao_projetos
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- Channel members: users can leave channels (delete their own membership)
CREATE POLICY "channel_members_delete_policy" ON channel_members_gestao_projetos
  FOR DELETE TO authenticated USING (user_id = auth.uid());;
