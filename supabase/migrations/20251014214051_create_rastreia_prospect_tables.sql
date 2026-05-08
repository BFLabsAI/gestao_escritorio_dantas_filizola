-- Criar tabelas principais para Rastreia Prospect

-- Tabela de vendedores
CREATE TABLE IF NOT EXISTS vendedores_rastreia_prospect (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  whatsapp TEXT,
  status TEXT DEFAULT 'Ativo',
  user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de cadências
CREATE TABLE IF NOT EXISTS cadencias_rastreia_prospect (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  config JSONB NOT NULL,
  is_padrao BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de listas de prospecção
CREATE TABLE IF NOT EXISTS listas_prospeccao_rastreia_prospect (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  descricao TEXT,
  vendedor_id UUID REFERENCES vendedores_rastreia_prospect(id),
  cadencia_id UUID REFERENCES cadencias_rastreia_prospect(id),
  status TEXT DEFAULT 'Ativa',
  total_leads INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de leads
CREATE TABLE IF NOT EXISTS leads_rastreia_prospect (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  telefone TEXT NOT NULL,
  email TEXT,
  empresa TEXT,
  cargo TEXT,
  lista_id UUID REFERENCES listas_prospeccao_rastreia_prospect(id),
  vendedor_id UUID REFERENCES vendedores_rastreia_prospect(id),
  dia_atual INTEGER DEFAULT 1,
  status TEXT DEFAULT 'normal',
  prioridade INTEGER DEFAULT 1,
  icp BOOLEAN DEFAULT FALSE,
  valor_ganho DECIMAL,
  utm_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de execuções de touchpoints
CREATE TABLE IF NOT EXISTS execucoes_touchpoints_rastreia_prospect (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id UUID REFERENCES leads_rastreia_prospect(id),
  dia INTEGER NOT NULL,
  canal TEXT NOT NULL,
  status TEXT DEFAULT 'pendente',
  horario TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);;
