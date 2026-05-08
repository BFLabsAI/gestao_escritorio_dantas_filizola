CREATE TABLE project_templates_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  structure JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);;
