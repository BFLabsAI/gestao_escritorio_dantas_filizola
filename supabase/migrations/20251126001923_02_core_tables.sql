CREATE TABLE users_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE clients_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  logo_url TEXT,
  cnpj TEXT,
  contact_email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE projects_gestao_projetos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID REFERENCES clients_gestao_projetos(id) ON DELETE CASCADE,
  manager_id UUID REFERENCES users_gestao_projetos(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  status project_status DEFAULT 'PLANNING',
  created_at TIMESTAMPTZ DEFAULT NOW()
);;
