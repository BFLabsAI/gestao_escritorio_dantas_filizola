-- Enable Row Level Security on all BF Tickets tables
ALTER TABLE conversations_bf_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages_bf_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups_bf_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE tagged_groups_bf_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE media_files_bf_tickets ENABLE ROW LEVEL SECURITY;

-- Create Security Policy for authenticated users
-- Since this is a personal system, we'll allow authenticated users to manage all data
-- while keeping the system secure from unauthorized access

-- conversations_bf_tickets policies
CREATE POLICY "Users can view all conversations" ON conversations_bf_tickets
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert conversations" ON conversations_bf_tickets
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update conversations" ON conversations_bf_tickets
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete conversations" ON conversations_bf_tickets
  FOR DELETE USING (auth.role() = 'authenticated');

-- messages_bf_tickets policies
CREATE POLICY "Users can view all messages" ON messages_bf_tickets
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert messages" ON messages_bf_tickets
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update messages" ON messages_bf_tickets
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete messages" ON messages_bf_tickets
  FOR DELETE USING (auth.role() = 'authenticated');

-- groups_bf_tickets policies
CREATE POLICY "Users can view all groups" ON groups_bf_tickets
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert groups" ON groups_bf_tickets
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update groups" ON groups_bf_tickets
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete groups" ON groups_bf_tickets
  FOR DELETE USING (auth.role() = 'authenticated');

-- tagged_groups_bf_tickets policies
CREATE POLICY "Users can view all tagged groups" ON tagged_groups_bf_tickets
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert tagged groups" ON tagged_groups_bf_tickets
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update tagged groups" ON tagged_groups_bf_tickets
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete tagged groups" ON tagged_groups_bf_tickets
  FOR DELETE USING (auth.role() = 'authenticated');

-- media_files_bf_tickets policies
CREATE POLICY "Users can view all media files" ON media_files_bf_tickets
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert media files" ON media_files_bf_tickets
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update media files" ON media_files_bf_tickets
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete media files" ON media_files_bf_tickets
  FOR DELETE USING (auth.role() = 'authenticated');

-- Edge Functions need special permissions for webhooks
-- Allow anonymous access to Edge Functions for Evolution API webhooks
-- This will be handled in the Edge Functions themselves with proper validation

-- Grant necessary permissions to authenticated users
GRANT ALL ON conversations_bf_tickets TO authenticated;
GRANT ALL ON messages_bf_tickets TO authenticated;
GRANT ALL ON groups_bf_tickets TO authenticated;
GRANT ALL ON tagged_groups_bf_tickets TO authenticated;
GRANT ALL ON media_files_bf_tickets TO authenticated;

-- Grant usage permissions on sequences for UUID generation
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;;
