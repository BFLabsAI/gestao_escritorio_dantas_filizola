CREATE TABLE goals_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects_gestao_projetos(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES goals_gestao_projetos(id) ON DELETE CASCADE,
  type goal_type NOT NULL,
  title TEXT NOT NULL,
  current_value FLOAT DEFAULT 0,
  target_value FLOAT DEFAULT 100,
  unit TEXT DEFAULT '%',
  progress FLOAT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE key_result_history_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  goal_id UUID REFERENCES goals_gestao_projetos(id) ON DELETE CASCADE,
  date TIMESTAMPTZ DEFAULT NOW(),
  value FLOAT NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE quick_wins_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects_gestao_projetos(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);;
