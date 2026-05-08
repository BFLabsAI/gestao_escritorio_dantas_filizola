-- Políticas RLS para tabelas do Rastreia Prospect

-- Vendedores
ALTER TABLE vendedores_rastreia_prospect ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendedores são visíveis para usuários autenticados" ON vendedores_rastreia_prospect
  FOR SELECT USING (auth.role() = 'authenticated');

-- Cadências
ALTER TABLE cadencias_rastreia_prospect ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Cadências são visíveis para usuários autenticados" ON cadencias_rastreia_prospect
  FOR SELECT USING (auth.role() = 'authenticated');

-- Listas de prospecção
ALTER TABLE listas_prospeccao_rastreia_prospect ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Listas são visíveis para usuários autenticados" ON listas_prospeccao_rastreia_prospect
  FOR SELECT USING (auth.role() = 'authenticated');

-- Leads
ALTER TABLE leads_rastreia_prospect ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendedores podem ver leads de suas listas" ON leads_rastreia_prospect
  FOR SELECT USING (auth.role() = 'authenticated');

-- Execuções de touchpoints
ALTER TABLE execucoes_touchpoints_rastreia_prospect ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendedores podem ver touchpoints de seus leads" ON execucoes_touchpoints_rastreia_prospect
  FOR SELECT USING (auth.role() = 'authenticated');;
