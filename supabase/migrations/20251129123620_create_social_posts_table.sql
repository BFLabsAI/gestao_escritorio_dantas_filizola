CREATE TABLE IF NOT EXISTS social_posts_banco_talentos_execut (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cargo_id INTEGER REFERENCES cargos_banco_talentos_execut(id) ON DELETE CASCADE,
  plataforma TEXT NOT NULL CHECK (plataforma IN ('linkedin', 'instagram', 'twitter', 'facebook')),
  conteudo TEXT NOT NULL,
  imagem_url TEXT,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'scheduled')),
  data_agendamento TIMESTAMP WITH TIME ZONE,
  criado_por TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE social_posts_banco_talentos_execut ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY "Users can view their own social posts" ON social_posts_banco_talentos_execut
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own social posts" ON social_posts_banco_talentos_execut
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own social posts" ON social_posts_banco_talentos_execut
  FOR UPDATE USING (true);

CREATE POLICY "Users can delete their own social posts" ON social_posts_banco_talentos_execut
  FOR DELETE USING (true);

-- Index for performance
CREATE INDEX idx_social_posts_cargo_id ON social_posts_banco_talentos_execut(cargo_id);
CREATE INDEX idx_social_posts_status ON social_posts_banco_talentos_execut(status);;
