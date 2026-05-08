-- ============================================================================
-- LEADS_EVOLUXHUB
-- Pipeline de vendas / CRM
-- ============================================================================
-- Tabela para gerenciar leads no pipeline de vendas da clínica
-- ============================================================================

CREATE TABLE IF NOT EXISTS leads_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  value DECIMAL(10,2) NOT NULL DEFAULT 0,
  stage TEXT NOT NULL DEFAULT 'novo_lead' CHECK (stage IN ('novo_lead', 'qualificacao', 'consulta_agendada', 'consulta_realizada', 'negociacao', 'ganho', 'perdido')),
  source TEXT,
  notes TEXT,
  patient_id UUID REFERENCES patients_evoluxhub(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Indexes para performance
CREATE INDEX IF NOT EXISTS idx_leads_evoluxhub_stage ON leads_evoluxhub(stage);
CREATE INDEX IF NOT EXISTS idx_leads_evoluxhub_created_at ON leads_evoluxhub(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_leads_evoluxhub_patient_id ON leads_evoluxhub(patient_id);
-- Comment
COMMENT ON TABLE leads_evoluxhub IS 'Pipeline de vendas / CRM - Leads da clínica';
COMMENT ON COLUMN leads_evoluxhub.stage IS 'Estágio do lead no pipeline: novo_lead, qualificacao, consulta_agendada, consulta_realizada, negociacao, ganho, perdido';
COMMENT ON COLUMN leads_evoluxhub.patient_id IS 'Referência para o paciente quando o lead é convertido';
