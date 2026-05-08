CREATE TABLE project_sections_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects_gestao_projetos(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE tasks_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects_gestao_projetos(id) ON DELETE CASCADE,
  section_id UUID REFERENCES project_sections_gestao_projetos(id) ON DELETE SET NULL,
  assignee_id UUID REFERENCES users_gestao_projetos(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMPTZ,
  due_date TIMESTAMPTZ,
  status task_status DEFAULT 'TODO',
  priority task_priority DEFAULT 'MEDIUM',
  tags TEXT[],
  dependencies UUID[],
  recurring_config JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE subtasks_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID REFERENCES tasks_gestao_projetos(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE comments_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID REFERENCES tasks_gestao_projetos(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users_gestao_projetos(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE attachments_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID REFERENCES tasks_gestao_projetos(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects_gestao_projetos(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  size_bytes BIGINT,
  type TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT attachments_owner_check CHECK (
    (task_id IS NOT NULL AND project_id IS NULL) OR 
    (task_id IS NULL AND project_id IS NOT NULL)
  )
);;
