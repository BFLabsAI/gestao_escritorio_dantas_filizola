DROP TABLE IF EXISTS execucoes_touchpoints_rastreia_prospect;

CREATE TABLE execucoes_touchpoints_rastreia_prospect (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  lead_id UUID NOT NULL REFERENCES leads_rastreia_prospect(id) ON DELETE CASCADE,
  touchpoint_id VARCHAR(255) NOT NULL,
  cadencia_id UUID REFERENCES cadencias_rastreia_prospect(id) ON DELETE CASCADE,
  dia INTEGER NOT NULL,
  tipo VARCHAR(50) NOT NULL,
  canal VARCHAR(50) NOT NULL,
  status VARCHAR(20) DEFAULT 'pendente' CHECK (status IN ('pendente', 'completo', 'efetivo', 'nao_efetivo', 'atrasado')),
  executado BOOLEAN DEFAULT FALSE,
  observacoes TEXT,
  data_execucao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_execucoes_touchpoints_lead_id ON execucoes_touchpoints_rastreia_prospect(lead_id);
CREATE INDEX IF NOT EXISTS idx_execucoes_touchpoints_cadencia_id ON execucoes_touchpoints_rastreia_prospect(cadencia_id);
CREATE INDEX IF NOT EXISTS idx_execucoes_touchpoints_dia ON execucoes_touchpoints_rastreia_prospect(dia);
CREATE INDEX IF NOT EXISTS idx_execucoes_touchpoints_touchpoint_id ON execucoes_touchpoints_rastreia_prospect(touchpoint_id);;
