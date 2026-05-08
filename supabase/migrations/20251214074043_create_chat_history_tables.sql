CREATE TABLE IF NOT EXISTS chat_sessions_audita_lead (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  title text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS chat_messages_audita_lead (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid REFERENCES chat_sessions_audita_lead(id) ON DELETE CASCADE NOT NULL,
  role text NOT NULL CHECK (role IN ('user', 'assistant')),
  content text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE chat_sessions_audita_lead ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages_audita_lead ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'chat_sessions_audita_lead' AND policyname = 'Users can manage their own chat sessions'
    ) THEN
        CREATE POLICY "Users can manage their own chat sessions"
        ON chat_sessions_audita_lead
        FOR ALL
        USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'chat_messages_audita_lead' AND policyname = 'Users can manage messages in their sessions'
    ) THEN
        CREATE POLICY "Users can manage messages in their sessions"
        ON chat_messages_audita_lead
        FOR ALL
        USING (
          session_id IN (
            SELECT id FROM chat_sessions_audita_lead WHERE user_id = auth.uid()
          )
        );
    END IF;
END $$;;
